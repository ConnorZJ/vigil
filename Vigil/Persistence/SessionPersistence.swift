import Foundation

struct SessionPersistence {
    private let fileStore: JSONFileStore
    private let paths: Paths

    init(fileStore: JSONFileStore = JSONFileStore(), paths: Paths = Paths()) {
        self.fileStore = fileStore
        self.paths = paths
    }

    func save(_ snapshots: [SessionSnapshot]) throws {
        try fileStore.save(snapshots, to: paths.sessionPersistenceFile)
    }

    func load(now: Date = Date()) throws -> [SessionSnapshot] {
        let snapshots = try fileStore.load([SessionSnapshot].self, from: paths.sessionPersistenceFile) ?? []
        return snapshots.filter { snapshot in
            guard snapshot.status == .complete else {
                return true
            }

            return now.timeIntervalSince(snapshot.updatedAt) <= 10 * 60
        }
    }
}
