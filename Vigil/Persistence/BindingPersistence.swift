import Foundation

protocol BindingPersisting {
    func load() throws -> [String: WindowSignature]
    func save(_ bindings: [String: WindowSignature]) throws
}

struct BindingPersistence: BindingPersisting {
    let fileStore: JSONFileStore
    let paths: Paths

    init(fileStore: JSONFileStore = JSONFileStore(), paths: Paths = Paths()) {
        self.fileStore = fileStore
        self.paths = paths
    }

    func load() throws -> [String: WindowSignature] {
        try fileStore.load([String: WindowSignature].self, from: paths.bindingPersistenceFile) ?? [:]
    }

    func save(_ bindings: [String: WindowSignature]) throws {
        try fileStore.save(bindings, to: paths.bindingPersistenceFile)
    }
}
