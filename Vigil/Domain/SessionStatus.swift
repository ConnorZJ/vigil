enum SessionStatus: String, Codable, Equatable {
    case running
    case waitingInput
    case permission
    case complete
    case error
    case unknown

    var requiresAttention: Bool {
        switch self {
        case .waitingInput, .permission, .error:
            return true
        case .running, .complete, .unknown:
            return false
        }
    }
}
