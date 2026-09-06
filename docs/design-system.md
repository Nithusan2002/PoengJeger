# Poengjeger design system

Poengjeger is a calm decision tool for the moment before a purchase. The interface should help people understand the best earning path in under a minute. Information, conditions, deadlines, and source quality always matter more than decoration.

`DesignTokens.swift` is the source of truth for visual values in the iOS app. Use a named token whenever you add a color, spacing value, corner radius, font, stroke width, or opacity. Do not add one-off visual values inside a feature view.

## Principles

1. Make the answer easy to scan. Lead with earning value, program, deadline, and required action.
2. Keep facts separate from editorial judgment. Requirements and source details must never look like recommendations.
3. Use color as a signal. Large decorative color fields make the app feel like a noisy deal feed.
4. Prefer hierarchy over containers. Use a card only when a section needs a real boundary.
5. Keep the experience trustworthy. Commercial content must be clearly labeled and must not change the visual meaning of a ranking.
6. Design for both color schemes, Dynamic Type, VoiceOver, and increased contrast from the start.

## Color

Poengjeger teal identifies the app and its primary actions. EuroBonus blue and Trumf red identify their programs only; they do not indicate success, warning, or ranking.

Olive marks an opportunity or editorial highlight. Amber marks a deadline or a point that needs attention. Warning red is reserved for risk, uncertainty, or something the user must check before purchasing. Green means verified, complete, or successful; it never means "high value."

Use `background` for the page, `surface` for ordinary content, and `surfaceElevated` only when a block needs stronger separation. Use soft colors behind short labels and icons, not as full-screen decoration. Text should normally use the semantic `textPrimary`, `textSecondary`, and `textTertiary` tokens so iOS can adapt contrast automatically.

Never communicate status with color alone. Pair it with text, an icon, or both. Text and essential controls should meet WCAG AA contrast: 4.5:1 for normal text and 3:1 for large text and meaningful interface elements.

## Spacing

The core rhythm is 4, 8, 12, 16, 24, and 32 points. Use these first:

- `xSmall` (4): a very tight internal gap.
- `medium` (8): related icon-and-label spacing.
- `standard` (12): compact control and row spacing.
- `screen` (16): default screen inset and card padding.
- `section` (24): separation between content groups.
- `xxLarge` (32): separation between major regions.

The other named spacing tokens preserve layouts already used by the app. Reuse them only when the component or alignment calls for that exact value. Do not extend the scale for a single screen without first checking whether a core token works.

Spacing communicates relationship: items inside a group sit closer together than separate groups. Avoid nested cards and stacked padding that create accidental oversized gaps.

## Corner radius and shape

Use `small` (8) for compact rows, tags, and small controls; `medium` (12) or `card` (14) for ordinary cards; `largeCard` (16) or `prominentCard` (18) for larger decision surfaces. `hero` (22) is reserved for rare high-emphasis containers. Use `badge` (6) for very small labels.

Use continuous rounded rectangles. Pills should use `Capsule` and circular program marks should use `Circle`; they do not need a radius token. A larger radius must communicate stronger grouping or emphasis, not decoration.

## Typography

Use the system typeface for interface copy and a system serif only for editorial or value-led display headings. Rounded heavy type is reserved for short earning values and the onboarding hero. Do not use it for paragraphs or general navigation.

Choose a named typography role from `DesignTokens.Typography`. Keep the hierarchy simple:

- Display roles: one short value or page statement.
- Title roles: screen and section titles.
- Headline roles: card and row titles.
- Body, callout, and subheadline roles: explanations and actions.
- Footnote and caption roles: metadata, sources, dates, and compact labels.

All text must support Dynamic Type. Prefer the semantic text-style tokens. The two fixed-size display tokens exist for the current value-led layouts; do not use them for long or essential text. Avoid truncating requirements, warnings, and source information.

## Components and states

Primary buttons use `brandPrimaryButton` with `textOnStrongColor`. Limit a screen region to one obvious primary action. Secondary actions should rely on text, border, or a soft surface rather than another filled button.

Cards use a surface color, one radius, and at most a subtle border. Shadows are optional and must stay quiet. A campaign card should answer what the user gets, which program applies, when it ends, and what they must do.

Loading, empty, error, disabled, selected, and saved states must be explicit. Do not show placeholder data that could be mistaken for a real campaign. Disabled controls need more than reduced opacity when their state may be unclear.

## Accessibility and content

Touch targets should be at least 44 by 44 points. Keep logical reading order, useful VoiceOver labels, and enough room for larger text. Icons that repeat a visible label should be hidden from accessibility; icon-only controls need a clear accessibility label.

Write short, concrete Norwegian copy. Put the action first. Show dates and deadlines explicitly, and place critical caveats before the handoff button. Never rely on an unexplained star rating or promotional wording to communicate value.

## Using and changing tokens

Use tokens by purpose, for example `DesignTokens.Colors.warning` rather than choosing a red because it looks close. All feature views use `DesignTokens` directly; the retired `PoengjegerTheme` facade must not be reintroduced.

When a new visual value is genuinely needed, add it to `DesignTokens.swift`, give it a purpose-based name, verify light and dark mode, and update this document if the rule changes. A new token should solve a repeated design need, not preserve an isolated adjustment.
