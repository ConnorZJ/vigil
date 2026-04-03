import Foundation
import XCTest
@testable import Vigil

final class HTTPMessageParserTests: XCTestCase {
    func testParsesRequestLineHeadersAndBody() throws {
        let parser = HTTPMessageParser(maxRequestSize: 64 * 1024)
        let requestData = Data((
            "POST /v1/events HTTP/1.1\r\n" +
            "Authorization: Bearer secret\r\n" +
            "Content-Length: 2\r\n\r\n{}"
        ).utf8)

        let request = try parser.parse(requestData)

        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.path, "/v1/events")
        XCTAssertEqual(request.headers["Authorization"], "Bearer secret")
        XCTAssertEqual(request.body, Data("{}".utf8))
    }

    func testRejectsRequestWithoutHeaderTerminator() {
        let parser = HTTPMessageParser(maxRequestSize: 64 * 1024)
        let requestData = Data("POST /v1/events HTTP/1.1\r\nAuthorization: Bearer secret".utf8)

        XCTAssertThrowsError(try parser.parse(requestData))
    }

    func testRejectsBodyShorterThanContentLength() {
        let parser = HTTPMessageParser(maxRequestSize: 64 * 1024)
        let requestData = Data((
            "POST /v1/events HTTP/1.1\r\n" +
            "Content-Length: 10\r\n\r\n{}"
        ).utf8)

        XCTAssertThrowsError(try parser.parse(requestData))
    }

    func testRejectsOversizedRequest() {
        let parser = HTTPMessageParser(maxRequestSize: 10)
        let requestData = Data((
            "GET /v1/health HTTP/1.1\r\n" +
            "Host: localhost\r\n\r\n"
        ).utf8)

        XCTAssertThrowsError(try parser.parse(requestData))
    }

    func testSerializesResponseWithConnectionClose() throws {
        let response = EventIngestionResponse(
            statusCode: 200,
            body: Data("{\"ok\":true}".utf8),
            headers: ["Content-Type": "application/json"]
        )

        let serialized = try HTTPMessageSerializer().serialize(response)
        let text = String(decoding: serialized, as: UTF8.self)

        XCTAssertTrue(text.contains("HTTP/1.1 200 OK"))
        XCTAssertTrue(text.contains("Connection: close"))
        XCTAssertTrue(text.contains("Content-Type: application/json"))
    }

    func testSerializesHealthResponseAsJsonBody() throws {
        let response = EventIngestionResponse(
            statusCode: 200,
            body: Data("{\"ok\":true}".utf8),
            headers: ["Content-Type": "application/json"]
        )

        let serialized = try HTTPMessageSerializer().serialize(response)
        let text = String(decoding: serialized, as: UTF8.self)

        XCTAssertTrue(text.contains("{\"ok\":true}"))
    }
}
