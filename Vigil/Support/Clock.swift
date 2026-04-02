import Foundation

protocol TimeProviding {
    var now: Date { get }
}

struct SystemTimeProvider: TimeProviding {
    var now: Date { Date() }
}

struct FixedClock: TimeProviding {
    let now: Date

    init(now: Date = Date(timeIntervalSince1970: 1_712_000_000)) {
        self.now = now
    }
}
