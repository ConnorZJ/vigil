struct SessionMenuActions {
    var openSession: (String) -> Void
    var bindFrontmostWindow: (String) -> Void
    var refreshMappings: () -> Void
    var openSettings: () -> Void

    static let noop = SessionMenuActions(
        openSession: { _ in },
        bindFrontmostWindow: { _ in },
        refreshMappings: {},
        openSettings: {}
    )
}
