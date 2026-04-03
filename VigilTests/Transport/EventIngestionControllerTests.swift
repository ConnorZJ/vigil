import Foundation
import XCTest
@testable import Vigil

final class EventIngestionControllerTests: XCTestCase {
    func testHealthRouteReturnsJsonBody() throws {
        let store = SessionStore(clock: FixedClock())
        let controller = EventIngestionController(expectedToken: "secret", sessionStore: store)

        let response = try controller.handle(
            request: .init(
                method: "GET",
                path: "/v1/health",
                headers: [:],
                body: Data()
            )
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(String(decoding: response.body, as: UTF8.self), "{\"ok\":true}")
    }

    func testWrongMethodOnKnownRouteReturns405() throws {
        let store = SessionStore(clock: FixedClock())
        let controller = EventIngestionController(expectedToken: "secret", sessionStore: store)

        let response = try controller.handle(
            request: .init(
                method: "GET",
                path: "/v1/events",
                headers: ["Authorization": "Bearer secret"],
                body: Data()
            )
        )

        XCTAssertEqual(response.statusCode, 405)
    }

    func testUnknownRouteReturns404() throws {
        let store = SessionStore(clock: FixedClock())
        let controller = EventIngestionController(expectedToken: "secret", sessionStore: store)

        let response = try controller.handle(
            request: .init(
                method: "GET",
                path: "/v1/unknown",
                headers: ["Authorization": "Bearer secret"],
                body: Data()
            )
        )

        XCTAssertEqual(response.statusCode, 404)
    }

    func testRejectsMissingAuthorization() throws {
        let store = SessionStore(clock: FixedClock())
        let controller = EventIngestionController(expectedToken: "secret", sessionStore: store)

        let response = try controller.handle(
            request: .init(
                method: "POST",
                path: "/v1/events",
                headers: [:],
                body: Data()
            )
        )

        XCTAssertEqual(response.statusCode, 401)
    }

    func testRejectsMalformedJSON() throws {
        let store = SessionStore(clock: FixedClock())
        let controller = EventIngestionController(expectedToken: "secret", sessionStore: store)

        let response = try controller.handle(
            request: .init(
                method: "POST",
                path: "/v1/events",
                headers: ["Authorization": "Bearer secret"],
                body: Data("not-json".utf8)
            )
        )

        XCTAssertEqual(response.statusCode, 400)
    }

    func testAcceptsFullSnapshotEvent() throws {
        let store = SessionStore(clock: FixedClock())
        let controller = EventIngestionController(expectedToken: "secret", sessionStore: store)
        let event = makeEvent(status: .waitingInput)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let response = try controller.handle(
            request: .init(
                method: "POST",
                path: "/v1/events",
                headers: ["Authorization": "Bearer secret"],
                body: try encoder.encode(event)
            )
        )

        XCTAssertEqual(response.statusCode, 202)
        XCTAssertEqual(store.snapshot(for: event.session.sessionId)?.status, .waitingInput)
    }

    private func makeEvent(status: SessionStatus) -> SessionEvent {
        let now = FixedClock().now
        let snapshot = SessionSnapshot(
            sessionId: "session-1",
            sessionTitle: "title",
            projectPath: "/tmp/project",
            projectName: "project",
            terminalApp: "ghostty",
            status: status,
            updatedAt: now
        )

        return SessionEvent(
            eventId: UUID().uuidString,
            eventType: "session.updated",
            sentAt: now,
            session: snapshot
        )
    }
}
