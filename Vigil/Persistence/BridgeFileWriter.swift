import Foundation

protocol BridgeWriting {
    func write(port: Int, token: String) throws
}

struct BridgeFileWriter: BridgeWriting {
    struct BridgeFile: Codable, Equatable {
        let version: Int
        let port: Int
        let token: String
        let updatedAt: Date
    }

    let fileStore: JSONFileStore
    let paths: Paths
    let clock: TimeProviding

    init(fileStore: JSONFileStore = JSONFileStore(), paths: Paths = Paths(), clock: TimeProviding = SystemTimeProvider()) {
        self.fileStore = fileStore
        self.paths = paths
        self.clock = clock
    }

    func write(port: Int, token: String) throws {
        let bridgeFile = BridgeFile(version: 1, port: port, token: token, updatedAt: clock.now)
        try fileStore.save(bridgeFile, to: paths.bridgeFile)
    }
}
