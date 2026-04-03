import Foundation
import Network

final class EmbeddedHTTPServer: TransportServing {
    private let sessionStore: SessionStore
    private let authTokenProvider: AuthTokenProvider
    private let bridgeWriter: BridgeWriting
    private let requestTimeout: TimeInterval
    private let queue = DispatchQueue(label: "Vigil.EmbeddedHTTPServer")
    private var listener: NWListener?
    private var controller: EventIngestionController?
    private var activeConnections: [UUID: HTTPServerConnection] = [:]

    private(set) var port: Int?
    private(set) var token: String?
    private(set) var isListening = false
    private(set) var bridgeWriteSucceeded = false
    private(set) var lastErrorStage: TransportErrorStage?
    private(set) var lastErrorMessage: String?
    private(set) var lastReceivedEventAt: Date?
    var onStateChange: (() -> Void)?

    init(
        sessionStore: SessionStore,
        authTokenProvider: AuthTokenProvider = AuthTokenProvider(),
        bridgeWriter: BridgeWriting = BridgeFileWriter(),
        requestTimeout: TimeInterval = 1.0
    ) {
        self.sessionStore = sessionStore
        self.authTokenProvider = authTokenProvider
        self.bridgeWriter = bridgeWriter
        self.requestTimeout = requestTimeout
    }

    func start(port: Int = 48127) throws {
        let token = try authTokenProvider.loadOrCreateToken()
        self.token = token
        self.controller = EventIngestionController(expectedToken: token, sessionStore: sessionStore)

        let listenerPort = NWEndpoint.Port(rawValue: UInt16(port))!
        let listener = try NWListener(using: .tcp, on: listenerPort)
        self.listener = listener

        let ready = DispatchSemaphore(value: 0)
        var startupError: Error?

        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }

            switch state {
            case .ready:
                self.isListening = true
                self.port = Int(listener.port?.rawValue ?? 0)
                self.bridgeWriteSucceeded = false
                if let boundPort = self.port, let token = self.token {
                    do {
                        try self.bridgeWriter.write(port: boundPort, token: token)
                        self.bridgeWriteSucceeded = true
                    } catch {
                        self.lastErrorStage = .listener
                        self.lastErrorMessage = error.localizedDescription
                        startupError = error
                    }
                }
                self.onStateChange?()
                ready.signal()
            case .failed(let error):
                self.lastErrorStage = .listener
                self.lastErrorMessage = error.localizedDescription
                self.onStateChange?()
                startupError = error
                ready.signal()
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            guard let self, let controller = self.controller else { return }
            let connectionID = UUID()
            let serverConnection = HTTPServerConnection(
                connection: connection,
                controller: controller,
                parser: HTTPMessageParser(maxRequestSize: 64 * 1024),
                serializer: HTTPMessageSerializer(),
                queue: self.queue,
                timeout: self.requestTimeout,
                onError: { stage, message in
                    self.lastErrorStage = stage
                    self.lastErrorMessage = message
                    self.onStateChange?()
                },
                onAcceptedEvent: {
                    self.lastReceivedEventAt = Date()
                    self.onStateChange?()
                },
                onClose: { [weak self] in
                    guard let self else { return }
                    self.activeConnections.removeValue(forKey: connectionID)
                }
            )
            self.activeConnections[connectionID] = serverConnection
            connection.start(queue: self.queue)
            serverConnection.start()
        }

        listener.start(queue: queue)

        if ready.wait(timeout: .now() + 2.0) == .timedOut {
            throw NSError(domain: "Vigil.EmbeddedHTTPServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Listener startup timed out"])
        }

        if let startupError {
            throw startupError
        }
    }

    func stop() {
        activeConnections.removeAll()
        listener?.cancel()
        listener = nil
        isListening = false
        onStateChange?()
    }

    func makeController() -> EventIngestionController? {
        controller
    }
}
