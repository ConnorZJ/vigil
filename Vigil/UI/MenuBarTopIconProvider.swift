import AppKit

final class MenuBarTopIconProvider {
    private struct PixelRect {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let color: NSColor

        init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: NSColor) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
            self.color = color
        }
    }

    private let canvasSize: CGFloat = 16
    private let imageSize = NSSize(width: 18, height: 18)
    let bodyFrame = CGRect(x: 3, y: 3, width: 10, height: 10)

    func image(for state: MenuBarIconState) -> NSImage? {
        image(for: state, frame: 0)
    }

    func image(for state: MenuBarIconState, frame: Int) -> NSImage? {
        let rects = rects(for: state, frame: frame)
        guard !rects.isEmpty else {
            return nil
        }

        let image = NSImage(size: imageSize, flipped: false) { [canvasSize, imageSize] bounds in
            guard let context = NSGraphicsContext.current?.cgContext else {
                return false
            }

            context.saveGState()
            context.setShouldAntialias(false)
            let scaleX = imageSize.width / canvasSize
            let scaleY = imageSize.height / canvasSize

            for rect in rects {
                rect.color.setFill()
                let drawRect = NSRect(
                    x: rect.x * scaleX,
                    y: bounds.height - ((rect.y + rect.height) * scaleY),
                    width: rect.width * scaleX,
                    height: rect.height * scaleY
                )
                NSBezierPath(rect: drawRect).fill()
            }

            context.restoreGState()
            return true
        }

        image.isTemplate = false
        return image
    }

    func frameCount(for state: MenuBarIconState) -> Int {
        switch state {
        case .idle:
            return 1
        case .running, .waitingInput, .permission, .complete, .error:
            return 2
        }
    }

    private func rects(for state: MenuBarIconState, frame: Int) -> [PixelRect] {
        switch state {
        case .idle:
            return [
                .init(x: bodyFrame.origin.x, y: bodyFrame.origin.y, width: bodyFrame.width, height: bodyFrame.height, color: .topIdle),
                .init(x: 5, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: 10, y: 7, width: 1, height: 1, color: .topFace)
            ]
        case .running:
            return [
                .init(x: bodyFrame.origin.x, y: bodyFrame.origin.y, width: bodyFrame.width, height: bodyFrame.height, color: .topSkin),
                .init(x: 5, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: 10, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: frame == 0 ? 12 : 1, y: frame == 0 ? 1 : 11, width: 2, height: 2, color: .topYellow)
            ]
        case .waitingInput:
            return [
                .init(x: bodyFrame.origin.x, y: bodyFrame.origin.y, width: bodyFrame.width, height: bodyFrame.height, color: .topSkin),
                .init(x: 5, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: 10, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: frame == 0 ? 12 : 11, y: 6, width: 1, height: 1, color: .topYellow),
                .init(x: frame == 0 ? 13 : 12, y: 6, width: 1, height: 1, color: .topYellow),
                .init(x: frame == 0 ? 14 : 13, y: 6, width: 1, height: 1, color: .topYellow)
            ]
        case .permission:
            return [
                .init(x: bodyFrame.origin.x, y: bodyFrame.origin.y, width: bodyFrame.width, height: bodyFrame.height, color: .topSkin),
                .init(x: 5, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: 10, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: 12, y: frame == 0 ? 3 : 2, width: 2, height: 4, color: .topBlue),
                .init(x: 12, y: 7, width: 2, height: 1, color: .white)
            ]
        case .complete:
            return [
                .init(x: bodyFrame.origin.x, y: bodyFrame.origin.y, width: bodyFrame.width, height: bodyFrame.height, color: .topSkin),
                .init(x: 5, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: 10, y: 7, width: 1, height: 1, color: .topFace),
                .init(x: 12, y: 2, width: 3, height: 3, color: .topGreen),
                .init(x: 13, y: frame == 0 ? 4 : 3, width: 1, height: 1, color: .white),
                .init(x: 14, y: frame == 0 ? 3 : 2, width: 1, height: 1, color: .white)
            ]
        case .error:
            return [
                .init(x: bodyFrame.origin.x, y: bodyFrame.origin.y, width: bodyFrame.width, height: bodyFrame.height, color: .topSkin),
                .init(x: 5, y: 6, width: 2, height: 2, color: .topFace),
                .init(x: 9, y: 6, width: 2, height: 2, color: .topFace),
                .init(x: 12, y: 2, width: 3, height: 3, color: .topRed),
                .init(x: 13, y: 3, width: 1, height: 1, color: .white),
                .init(x: 13, y: frame == 0 ? 4 : 5, width: 1, height: 1, color: .white)
            ]
        }
    }
}

private extension NSColor {
    static let topSkin = NSColor(hex: 0xD4956A)
    static let topFace = NSColor(hex: 0x1A1A2E)
    static let topIdle = NSColor(hex: 0x7A7A8A)
    static let topYellow = NSColor(hex: 0xFACC15)
    static let topRed = NSColor(hex: 0xF87171)
    static let topGreen = NSColor(hex: 0x4ADE80)
    static let topBlue = NSColor(hex: 0x60A5FA)

    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
