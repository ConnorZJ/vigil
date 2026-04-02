import SwiftUI

struct PopoverRootView: View {
    let presentation: PopoverPresentation
    let actions: SessionMenuActions
    private let iconProvider = PixelArtMenuIconProvider()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                summaryView

                ForEach(nonSpecialSections, id: \ .title) { section in
                    if !section.sessionCards.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.system(size: 12, weight: .semibold))

                            ForEach(section.sessionCards, id: \ .sessionId) { card in
                                SessionCardView(card: card, iconProvider: iconProvider, actions: actions)
                            }
                        }
                    }
                }

                DiagnosticsSectionView(diagnostics: presentation.diagnostics)
                UtilityActionsView(actions: actions)
            }
            .padding(12)
        }
        .frame(width: 360, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(presentation.summary.primaryStateLabel)
                .font(.system(size: 15, weight: .bold))

            Text("\(presentation.summary.trackedSessionCount) tracked · \(presentation.summary.attentionRequiredCount) need attention")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var nonSpecialSections: [PopoverSectionPresentation] {
        presentation.sections.filter { section in
            section.kind != .summary && section.kind != .diagnostics && section.kind != .utilityActions
        }
    }
}
