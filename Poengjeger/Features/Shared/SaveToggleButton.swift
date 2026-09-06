import SwiftUI

struct SaveToggleButton: View {
    let isSaved: Bool
    let savedAccessibilityLabel: String
    let unsavedAccessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isSaved ? "Lagret" : "Lagre", systemImage: isSaved ? "star.fill" : "star")
                .font(DesignTokens.Typography.subheadlineSemibold)
                .frame(minWidth: 92, minHeight: 40)
                .padding(.horizontal, DesignTokens.Spacing.xSmall)
                .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSaved ? DesignTokens.Colors.opportunity : DesignTokens.Colors.brandPrimary)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .fill(
                    isSaved
                        ? DesignTokens.Colors.opportunity.opacity(DesignTokens.Opacity.selected)
                        : DesignTokens.Colors.brandPrimary.opacity(DesignTokens.Opacity.subtle)
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(
                    isSaved
                        ? DesignTokens.Colors.opportunity.opacity(DesignTokens.Opacity.border)
                        : DesignTokens.Colors.border,
                    lineWidth: DesignTokens.Stroke.standard
                )
        }
        .minimumTouchTarget()
        .accessibilityLabel(isSaved ? savedAccessibilityLabel : unsavedAccessibilityLabel)
        .accessibilityValue(isSaved ? "Lagret" : "Ikke lagret")
    }
}
