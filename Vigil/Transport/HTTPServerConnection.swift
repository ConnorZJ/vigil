import Foundation
import Network

final class HTTPServerConnection {
    private let connection: NWConnection
    private let controller: EventIngestionController
    private let parser: HTTPMessageParser
    private let serializer: HTTPMessageSerializer
    private let queue: DispatchQueue
    private let timeout: TimeInterval
    private let onError: (TransportErrorStage, String) -> Void
    private let onAcceptedEvent: () -> Void
    private let onClose: () -> Void
    private var buffer = Data()
    private var timeoutWorkItem: DispatchWorkItem?

    init(
        connection: NWConnection,
        controller: EventIngestionController,
        parser: HTTPMessageParser,
        serializer: HTTPMessageSerializer,
        queue: DispatchQueue,
        timeout: TimeInterval,
        onError: @escaping (TransportErrorStage, String) -> Void,
        onAcceptedEvent: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.connection = connection
        self.controller = controller
        self.parser = parser
        self.serializer = serializer
        self.queue = queue
        self.timeout = timeout
        self.onError = onError
        self.onAcceptedEvent = onAcceptedEvent
        self.onClose = onClose
    }

    func start() {
        scheduleTimeout()
        receiveNextChunk()
    }

    private func receiveNextChunk() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: parser.maxRequestSize) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let error {
                self.onError(.listener, error.localizedDescription)
                self.close()
                return
            }

            if let data {
                self.buffer.append(data)
            }

            do {
                let request = try self.parser.parse(self.buffer)
                self.timeoutWorkItem?.cancel()
                let response = try self.controller.handle(request: request)
                if response.statusCode == 202 {
                    self.onAcceptedEvent()
                }
                try self.send(response)
            } catch let parseError as HTTPMessageParseError {
                switch parseError {
                case .missingHeaderTerminator, .incompleteBody:
                    if isComplete {
                        self.onError(.parse, "incomplete request")
                        self.sendBestEffortBadRequest()
                    } else {
                        self.receiveNextChunk()
                    }
                case .oversized:
                    self.onError(.parse, "request too large")
                    self.sendBestEffortBadRequest()
                case .invalidRequestLine, .invalidContentLength:
                    self.onError(.parse, "malformed request")
                    self.sendBestEffortBadRequest()
                }
            } catch {
                self.onError(.parse, error.localizedDescription)
                self.sendBestEffortBadRequest()
            }
        }
    }

    private func send(_ response: EventIngestionResponse) throws {
        let data = try serializer.serialize(response)
        connection.send(content: data, completion: .contentProcessed { [weak self] _ in
            self?.close()
        })
    }

    private func sendBestEffortBadRequest() {
        let response = EventIngestionResponse(statusCode: 400, body: Data(), headers: [:])
        let data = try? serializer.serialize(response)
        connection.send(content: data, completion: .contentProcessed { [weak self] _ in
            self?.close()
        })
    }

    private func scheduleTimeout() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.onError(.parse, "request timeout")
            self.close()
        }

        timeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + timeout, execute: workItem)
    }

    private func close() {
        timeoutWorkItem?.cancel()
        connection.cancel()
        onClose()
    }
}
