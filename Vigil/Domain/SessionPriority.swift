struct SessionPriority: Equatable {
    let value: Int

    init(status: SessionStatus, isStale: Bool = false) {
        let baseValue: Int

        switch status {
        case .error:
            baseValue = 5
        case .waitingInput:
            baseValue = 4
        case .permission:
            baseValue = 3
        case .complete:
            baseValue = 2
        case .running:
            baseValue = 1
        case .unknown:
            baseValue = 0
        }

        value = isStale ? max(0, baseValue - 1) : baseValue
    }
}
