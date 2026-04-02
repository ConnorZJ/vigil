import ApplicationServices
import Foundation

enum AXPermissionStatus: Equatable {
    case granted
    case denied
}

protocol AXPermissionProviding {
    var status: AXPermissionStatus { get }
    func requestAccessPrompt()
}

struct AXPermissionService: AXPermissionProviding {
    var status: AXPermissionStatus {
        AXIsProcessTrusted() ? .granted : .denied
    }

    func requestAccessPrompt() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
