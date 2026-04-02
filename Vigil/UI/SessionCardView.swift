import SwiftUI

struct SessionCardView: View {
    let card: PopoverSessionCardPresentation
    let iconProvider: PixelArtMenuIconProvider
    let actions: SessionMenuActions

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let image = iconProvider.image(for: card.iconState) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.system(size: 13, weight: .semibold))
                Text(card.projectName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(card.relativeUpdatedText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(card.statusBadgeText)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.quaternary)
                    .clipShape(Capsule())

                Button("Bind Frontmost") {
                    actions.bindFrontmostWindow(card.bindActionSessionId)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 10))
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture {
            actions.openSession(card.primaryActionSessionId)
        }
    }
}
