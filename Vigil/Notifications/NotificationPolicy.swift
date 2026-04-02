struct NotificationPolicy {
    func shouldNotify(previous: SessionSnapshot?, current: SessionSnapshot) -> Bool {
        guard current.status != .running else {
            return false
        }

        let notifiableStatuses: Set<SessionStatus> = [.waitingInput, .permission, .error, .complete]
        guard notifiableStatuses.contains(current.status) else {
            return false
        }

        guard let previous else {
            return true
        }

        return previous.status != current.status
    }
}
