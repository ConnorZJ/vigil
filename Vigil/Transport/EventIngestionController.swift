import Foundation

struct EventIngestionRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data
}

struct EventIngestionResponse {
    let statusCode: Int
    let body: Data
    let headers: [String: String]
}

final class EventIngestionController {
    private let expectedToken: String
    private let sessionStore: SessionStore
    private let decoder: JSONDecoder

    init(expectedToken: String, sessionStore: SessionStore) {
        self.expectedToken = expectedToken
        self.sessionStore = sessionStore

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func handle(request: EventIngestionRequest) throws -> EventIngestionResponse {
        if request.method == "GET", request.path == "/v1/health" {
            return EventIngestionResponse(
                statusCode: 200,
                body: Data("{\"ok\":true}".utf8),
                headers: ["Content-Type": "application/json"]
            )
        }

        guard request.headers["Authorization"] == "Bearer \(expectedToken)" else {
            return EventIngestionResponse(statusCode: 401, body: Data(), headers: [:])
        }

        if request.path == "/v1/events", request.method != "POST" {
            return EventIngestionResponse(statusCode: 405, body: Data(), headers: [:])
        }

        guard request.method == "POST", request.path == "/v1/events" else {
            return EventIngestionResponse(statusCode: 404, body: Data(), headers: [:])
        }

        do {
            let event = try decoder.decode(SessionEvent.self, from: request.body)
            sessionStore.apply(event: event)
            return EventIngestionResponse(statusCode: 202, body: Data(), headers: [:])
        } catch {
            return EventIngestionResponse(statusCode: 400, body: Data(), headers: [:])
        }
    }
}
