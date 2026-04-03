import Foundation

enum TransportErrorStage: String, Equatable {
    case listener
    case parse
    case auth
    case route
    case ingestion
    case action
}

struct TransportErrorFact: Equatable {
    let stage: TransportErrorStage
    let message: String
}

protocol TransportServing: AnyObject {
    var port: Int? { get }
    var token: String? { get }
    var isListening: Bool { get }
    var bridgeWriteSucceeded: Bool { get }
    var lastErrorStage: TransportErrorStage? { get }
    var lastErrorMessage: String? { get }
    var lastReceivedEventAt: Date? { get }
    var onStateChange: (() -> Void)? { get set }

    func start(port: Int) throws
    func stop()
}
