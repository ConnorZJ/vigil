import SwiftUI

struct DiagnosticsSectionView: View {
    let diagnostics: PopoverDiagnosticsPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Diagnostics")
                .font(.system(size: 12, weight: .semibold))

            Group {
                Text(diagnostics.transportStatus)
                Text(diagnostics.bridgeStatus)
                Text("Accessibility: \(diagnostics.accessibilityStatus)")
                Text("Last Event: \(diagnostics.lastEventText)")
                if let lastJumpError = diagnostics.lastJumpError {
                    Text("Last Jump Error: \(lastJumpError)")
                }
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
