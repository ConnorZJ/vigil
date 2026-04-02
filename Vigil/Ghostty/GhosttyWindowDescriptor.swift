import CoreGraphics

struct GhosttyWindowDescriptor: Equatable {
    let title: String
    let frame: CGRect
    let isFocused: Bool
    let cwd: String?
    let tabTitle: String?
    let tty: String?

    init(
        title: String,
        frame: CGRect,
        isFocused: Bool,
        cwd: String? = nil,
        tabTitle: String? = nil,
        tty: String? = nil
    ) {
        self.title = title
        self.frame = frame
        self.isFocused = isFocused
        self.cwd = cwd
        self.tabTitle = tabTitle
        self.tty = tty
    }
}
