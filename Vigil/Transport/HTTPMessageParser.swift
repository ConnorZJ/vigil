import Foundation

enum HTTPMessageParseError: Error {
    case oversized
    case missingHeaderTerminator
    case invalidRequestLine
    case invalidContentLength
    case incompleteBody
}

struct HTTPMessageParser {
    let maxRequestSize: Int

    func parse(_ data: Data) throws -> EventIngestionRequest {
        guard data.count <= maxRequestSize else {
            throw HTTPMessageParseError.oversized
        }

        let delimiter = Data("\r\n\r\n".utf8)
        guard let headerRange = data.range(of: delimiter) else {
            throw HTTPMessageParseError.missingHeaderTerminator
        }

        let headerData = data[..<headerRange.lowerBound]
        let bodyStart = headerRange.upperBound
        let bodyData = data[bodyStart...]

        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw HTTPMessageParseError.invalidRequestLine
        }

        var lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            throw HTTPMessageParseError.invalidRequestLine
        }
        lines.removeFirst()

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else {
            throw HTTPMessageParseError.invalidRequestLine
        }

        var headers: [String: String] = [:]
        for line in lines where !line.isEmpty {
            let components = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard components.count == 2 else { continue }
            headers[components[0].trimmingCharacters(in: .whitespaces)] = components[1].trimmingCharacters(in: .whitespaces)
        }

        let contentLength = headers["Content-Length"].flatMap(Int.init) ?? 0
        guard contentLength >= 0 else {
            throw HTTPMessageParseError.invalidContentLength
        }

        guard bodyData.count >= contentLength else {
            throw HTTPMessageParseError.incompleteBody
        }

        let body = bodyData.prefix(contentLength)

        return EventIngestionRequest(
            method: String(parts[0]),
            path: String(parts[1]),
            headers: headers,
            body: Data(body)
        )
    }
}

struct HTTPMessageSerializer {
    func serialize(_ response: EventIngestionResponse) throws -> Data {
        var headers = response.headers
        headers["Connection"] = "close"
        headers["Content-Length"] = String(response.body.count)

        let statusText: String
        switch response.statusCode {
        case 200: statusText = "OK"
        case 202: statusText = "Accepted"
        case 400: statusText = "Bad Request"
        case 401: statusText = "Unauthorized"
        case 404: statusText = "Not Found"
        case 405: statusText = "Method Not Allowed"
        default: statusText = "Error"
        }

        var lines = ["HTTP/1.1 \(response.statusCode) \(statusText)"]
        for key in headers.keys.sorted() {
            if let value = headers[key] {
                lines.append("\(key): \(value)")
            }
        }
        lines.append("")
        lines.append("")

        var serialized = Data(lines.joined(separator: "\r\n").utf8)
        serialized.append(response.body)
        return serialized
    }
}
