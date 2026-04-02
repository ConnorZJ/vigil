import Foundation

final class AuthTokenProvider {
    private let fileStore: JSONFileStore
    private let paths: Paths
    private let fileManager: FileManager

    init(
        fileStore: JSONFileStore = JSONFileStore(),
        paths: Paths = Paths(),
        fileManager: FileManager = .default
    ) {
        self.fileStore = fileStore
        self.paths = paths
        self.fileManager = fileManager
    }

    func loadOrCreateToken() throws -> String {
        let tokenURL = paths.appSupportDirectory.appendingPathComponent("auth-token.txt")

        if let existingData = try? Data(contentsOf: tokenURL),
           let existing = String(data: existingData, encoding: .utf8),
           !existing.isEmpty {
            return existing
        }

        let token = UUID().uuidString
        try fileManager.createDirectory(at: tokenURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(token.utf8).write(to: tokenURL, options: .atomic)
        return token
    }
}
