import AppKit

final class PixelArtMenuIconProvider {
    private struct PixelRect {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let color: NSColor
        let alpha: CGFloat

        init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: NSColor, alpha: CGFloat = 1) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
            self.color = color
            self.alpha = alpha
        }
    }

    private let canvasSize: CGFloat = 32
    private let imageSize = NSSize(width: 16, height: 16)

    func image(for state: MenuBarIconState) -> NSImage? {
        let rects = rects(for: state)
        guard !rects.isEmpty else {
            return nil
        }

        let image = NSImage(size: imageSize, flipped: false) { [imageSize, canvasSize] bounds in
            guard let context = NSGraphicsContext.current?.cgContext else {
                return false
            }

            context.saveGState()
            context.setShouldAntialias(false)
            let scaleX = imageSize.width / canvasSize
            let scaleY = imageSize.height / canvasSize

            for rect in rects {
                rect.color.withAlphaComponent(rect.alpha).setFill()
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

    private func rects(for state: MenuBarIconState) -> [PixelRect] {
        switch state {
        case .idle:
            return idleRects
        case .running:
            return runningRects
        case .waitingInput, .permission:
            return waitingRects
        case .complete:
            return completedRects
        case .error:
            return errorRects
        }
    }

    private var runningRects: [PixelRect] {
        [
            .init(x: 8, y: 4, width: 16, height: 4, color: .pixelSkin),
            .init(x: 6, y: 4, width: 2, height: 4, color: .pixelSkin),
            .init(x: 24, y: 4, width: 2, height: 4, color: .pixelSkin),
            .init(x: 6, y: 8, width: 20, height: 10, color: .pixelSkin),
            .init(x: 10, y: 10, width: 4, height: 4, color: .pixelFace),
            .init(x: 18, y: 10, width: 4, height: 4, color: .pixelFace),
            .init(x: 8, y: 18, width: 4, height: 5, color: .pixelSkin),
            .init(x: 14, y: 18, width: 4, height: 3, color: .pixelSkin),
            .init(x: 20, y: 18, width: 4, height: 5, color: .pixelSkin),
            .init(x: 28, y: 2, width: 2, height: 2, color: .pixelAccentYellow),
            .init(x: 2, y: 6, width: 2, height: 2, color: .pixelAccentYellow)
        ]
    }

    private var waitingRects: [PixelRect] {
        [
            .init(x: 8, y: 4, width: 16, height: 4, color: .pixelSkin),
            .init(x: 6, y: 4, width: 2, height: 4, color: .pixelSkin),
            .init(x: 24, y: 4, width: 2, height: 4, color: .pixelSkin),
            .init(x: 6, y: 8, width: 20, height: 10, color: .pixelSkin),
            .init(x: 10, y: 10, width: 4, height: 4, color: .pixelFace),
            .init(x: 18, y: 10, width: 4, height: 4, color: .pixelFace),
            .init(x: 8, y: 18, width: 4, height: 4, color: .pixelSkin),
            .init(x: 14, y: 18, width: 4, height: 4, color: .pixelSkin),
            .init(x: 20, y: 18, width: 4, height: 4, color: .pixelSkin),
            .init(x: 24, y: 6, width: 2, height: 2, color: .pixelAccentYellow),
            .init(x: 27, y: 6, width: 2, height: 2, color: .pixelAccentYellow),
            .init(x: 30, y: 6, width: 2, height: 2, color: .pixelAccentYellow)
        ]
    }

    private var errorRects: [PixelRect] {
        [
            .init(x: 8, y: 4, width: 16, height: 4, color: .pixelSkin),
            .init(x: 4, y: 6, width: 2, height: 4, color: .pixelSkin),
            .init(x: 26, y: 6, width: 2, height: 4, color: .pixelSkin),
            .init(x: 6, y: 8, width: 20, height: 10, color: .pixelSkin),
            .init(x: 10, y: 10, width: 2, height: 2, color: .pixelFace),
            .init(x: 12, y: 12, width: 2, height: 2, color: .pixelFace),
            .init(x: 12, y: 10, width: 2, height: 2, color: .pixelFace),
            .init(x: 10, y: 12, width: 2, height: 2, color: .pixelFace),
            .init(x: 18, y: 10, width: 2, height: 2, color: .pixelFace),
            .init(x: 20, y: 12, width: 2, height: 2, color: .pixelFace),
            .init(x: 20, y: 10, width: 2, height: 2, color: .pixelFace),
            .init(x: 18, y: 12, width: 2, height: 2, color: .pixelFace),
            .init(x: 8, y: 18, width: 4, height: 4, color: .pixelSkin),
            .init(x: 14, y: 18, width: 4, height: 4, color: .pixelSkin),
            .init(x: 20, y: 18, width: 4, height: 4, color: .pixelSkin),
            .init(x: 26, y: 0, width: 6, height: 6, color: .pixelAccentRed),
            .init(x: 28, y: 1, width: 2, height: 3, color: .white),
            .init(x: 28, y: 5, width: 2, height: 1, color: .white)
        ]
    }

    private var completedRects: [PixelRect] {
        [
            .init(x: 8, y: 6, width: 16, height: 4, color: .pixelSkin),
            .init(x: 6, y: 2, width: 2, height: 6, color: .pixelSkin),
            .init(x: 24, y: 2, width: 2, height: 6, color: .pixelSkin),
            .init(x: 6, y: 10, width: 20, height: 10, color: .pixelSkin),
            .init(x: 10, y: 12, width: 2, height: 2, color: .pixelFace),
            .init(x: 12, y: 14, width: 2, height: 2, color: .pixelFace),
            .init(x: 8, y: 14, width: 2, height: 2, color: .pixelFace),
            .init(x: 18, y: 12, width: 2, height: 2, color: .pixelFace),
            .init(x: 20, y: 14, width: 2, height: 2, color: .pixelFace),
            .init(x: 16, y: 14, width: 2, height: 2, color: .pixelFace),
            .init(x: 12, y: 17, width: 2, height: 2, color: .pixelFace),
            .init(x: 14, y: 18, width: 4, height: 2, color: .pixelFace),
            .init(x: 18, y: 17, width: 2, height: 2, color: .pixelFace),
            .init(x: 8, y: 20, width: 4, height: 4, color: .pixelSkin),
            .init(x: 14, y: 20, width: 4, height: 4, color: .pixelSkin),
            .init(x: 20, y: 20, width: 4, height: 4, color: .pixelSkin),
            .init(x: 26, y: 0, width: 6, height: 6, color: .pixelAccentGreen),
            .init(x: 27, y: 3, width: 2, height: 2, color: .white),
            .init(x: 29, y: 1, width: 2, height: 2, color: .white)
        ]
    }

    private var idleRects: [PixelRect] {
        [
            .init(x: 8, y: 6, width: 16, height: 4, color: .pixelIdleSkin, alpha: 0.5),
            .init(x: 4, y: 8, width: 4, height: 4, color: .pixelIdleSkin, alpha: 0.5),
            .init(x: 24, y: 8, width: 4, height: 4, color: .pixelIdleSkin, alpha: 0.5),
            .init(x: 6, y: 10, width: 20, height: 10, color: .pixelIdleSkin, alpha: 0.5),
            .init(x: 10, y: 13, width: 4, height: 2, color: .pixelFace, alpha: 0.4),
            .init(x: 18, y: 13, width: 4, height: 2, color: .pixelFace, alpha: 0.4),
            .init(x: 8, y: 20, width: 4, height: 2, color: .pixelIdleSkin, alpha: 0.5),
            .init(x: 14, y: 20, width: 4, height: 2, color: .pixelIdleSkin, alpha: 0.5),
            .init(x: 20, y: 20, width: 4, height: 2, color: .pixelIdleSkin, alpha: 0.5)
        ]
    }
}

private extension NSColor {
    static let pixelSkin = NSColor(hex: 0xD4956A)
    static let pixelFace = NSColor(hex: 0x1A1A2E)
    static let pixelAccentYellow = NSColor(hex: 0xFACC15)
    static let pixelAccentRed = NSColor(hex: 0xF87171)
    static let pixelAccentGreen = NSColor(hex: 0x4ADE80)
    static let pixelIdleSkin = NSColor(hex: 0x7A7A8A)

    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
