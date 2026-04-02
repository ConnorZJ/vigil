import CoreGraphics
import Foundation

struct WindowSignature: Codable, Equatable {
    let title: String
    let frame: CGRectCodable
    let observedAt: Date
}

struct CGRectCodable: Codable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(_ rect: CGRect) {
        self.init(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
    }
}
