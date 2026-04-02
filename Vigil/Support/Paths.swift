import Foundation

struct Paths {
    let rootURL: URL

    init(rootURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.rootURL = rootURL
    }

    var appSupportDirectory: URL {
        rootURL.appendingPathComponent("Library/Application Support/Vigil", isDirectory: true)
    }

    var configDirectory: URL {
        rootURL.appendingPathComponent(".config/vigil", isDirectory: true)
    }

    var bridgeFile: URL {
        configDirectory.appendingPathComponent("bridge.json")
    }

    var sessionPersistenceFile: URL {
        appSupportDirectory.appendingPathComponent("sessions.json")
    }

    var bindingPersistenceFile: URL {
        appSupportDirectory.appendingPathComponent("bindings.json")
    }
}
