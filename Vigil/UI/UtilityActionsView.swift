import SwiftUI

struct UtilityActionsView: View {
    let actions: SessionMenuActions

    var body: some View {
        HStack(spacing: 8) {
            Button("Refresh") {
                actions.refreshMappings()
            }

            Button("Accessibility") {
                actions.openSettings()
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .buttonStyle(.bordered)
        .font(.system(size: 11, weight: .medium))
    }
}
