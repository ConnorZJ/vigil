import Foundation
import Network
import XCTest
@testable import Vigil

final class EmbeddedHTTPServerTests: XCTestCase {
    func testStartTransitionsServerToActiveStateAndWritesBridgeFile() throws {
        let root = temporaryDirectory()
        let paths = Paths(rootURL: root)
        let sessionStore = SessionStore(clock: FixedClock())
        let server = EmbeddedHTTPServer(
            sessionStore: sessionStore,
            authTokenProvider: AuthTokenProvider(paths: paths),
            bridgeWriter: BridgeFileWriter(paths: paths, clock: FixedClock()),
            requestTimeout: 0.2
        )

        try server.start(port: 0)
        defer { server.stop() }

        XCTAssertTrue(server.isListening)
        XCTAssertNotNil(server.port)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.bridgeFile.path))
        XCTAssertTrue(server.bridgeWriteSucceeded)
    }

    func testHealthEndpointRespondsWithConnectionClose() async throws {
        let root = temporaryDirectory()
        let paths = Paths(rootURL: root)
        let sessionStore = SessionStore(clock: FixedClock())
        let server = EmbeddedHTTPServer(
            sessionStore: sessionStore,
            authTokenProvider: AuthTokenProvider(paths: paths),
            bridgeWriter: BridgeFileWriter(paths: paths, clock: FixedClock()),
            requestTimeout: 0.5
        )

        try server.start(port: 0)
        defer { server.stop() }

        let url = URL(string: "http://127.0.0.1:\(try XCTUnwrap(server.port))/v1/health")!
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)

        XCTAssertEqual(httpResponse.statusCode, 200)
        XCTAssertEqual(httpResponse.value(forHTTPHeaderField: "Connection"), "close")
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "{\"ok\":true}")
    }

    func testPartialRequestTriggersTimeoutErrorFact() throws {
        let root = temporaryDirectory()
        let paths = Paths(rootURL: root)
        let sessionStore = SessionStore(clock: FixedClock())
        let server = EmbeddedHTTPServer(
            sessionStore: sessionStore,
            authTokenProvider: AuthTokenProvider(paths: paths),
            bridgeWriter: BridgeFileWriter(paths: paths, clock: FixedClock()),
            requestTimeout: 0.2
        )

        try server.start(port: 0)
        defer { server.stop() }

        let port = try XCTUnwrap(server.port)
        let connection = NWConnection(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: UInt16(port))!, using: .tcp)
        let ready = expectation(description: "connection ready")
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                ready.fulfill()
            }
        }
        connection.start(queue: .global())
        wait(for: [ready], timeout: 1.0)

        connection.send(content: Data("POST /v1/events HTTP/1.1\r\nContent-Length: 10\r\n\r\n{}".utf8), completion: .contentProcessed { _ in })

        let timeoutExpectation = expectation(description: "timeout error recorded")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            if server.lastErrorStage == .parse, server.lastErrorMessage?.contains("timeout") == true {
                timeoutExpectation.fulfill()
            }
        }
        wait(for: [timeoutExpectation], timeout: 1.0)
        connection.cancel()
    }
}
