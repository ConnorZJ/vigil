protocol GhosttyWindowQuerying {
    func currentWindows() throws -> [GhosttyWindowDescriptor]
    func frontmostWindow() throws -> GhosttyWindowDescriptor?
}
