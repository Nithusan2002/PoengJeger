import SwiftUI

struct SaveToggleButton: View {
    let isSaved: Bool
    let savedAccessibilityLabel: String
    let unsavedAccessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isSaved ? "Lagret" : "Lagre", systemImage: isSaved ? "star.fill" : "star")
                .font(.subheadline.weight(.semibold))
                .frame(minWidth: 92, minHeight: 40)
                .padding(.horizontal, 4)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSaved ? PoengjegerTheme.highlight : PoengjegerTheme.accent)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSaved ? PoengjegerTheme.highlight.opacity(0.14) : PoengjegerTheme.accent.opacity(0.10))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSaved ? PoengjegerTheme.highlight.opacity(0.34) : PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityLabel(isSaved ? savedAccessibilityLabel : unsavedAccessibilityLabel)
        .accessibilityValue(isSaved ? "Lagret" : "Ikke lagret")
    }
}
