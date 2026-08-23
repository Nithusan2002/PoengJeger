# Poengjeger color palette exploration

## Goal

Poengjeger should feel modern, calm, premium, clear and trustworthy. The color system must support the core habit: check before you shop. Colors should clarify status and program identity without making the app feel like a noisy deal feed.

## Recommendation: Nordisk Tillit

Use a deep teal primary, clean neutral surfaces, and reserve strong colors for program identity and status.

| Role | HEX | Use |
| --- | --- | --- |
| Primary | `#0F766E` | App navigation, primary actions, search/category affordances |
| Primary soft | `#DDF3F0` | Icons, tags and low-emphasis selected states |
| Background | `#F7F8F6` | Main screen background |
| Surface | `#FFFFFF` | Main content surfaces |
| Elevated surface | `#FFFFFF` | Cards, search field and important content blocks |
| Campaign | `#B45309` | Active campaign markers such as "NA" and "AKTIV" |
| Campaign soft | `#FFF3E0` | Campaign context, not warning messages |
| Warning | `#B42318` | Risk, uncertainty and must-check copy |
| Warning soft | `#FCEAE8` | Warning callouts |
| Success | `#16803C` | Editorially verified or selected states |
| EuroBonus | `#2563A6` | EuroBonus identity |
| Trumf | `#C62835` | Trumf identity |

Why this is the best fit:

- It avoids a generic finance-blue interface while still feeling credible and fresh.
- It keeps EuroBonus and Trumf recognizable without letting either program own the whole app brand.
- It uses amber only for opportunity/status, so active campaigns are easy to scan. The implementation uses the darker accessible amber `#B45309` for white badge text.
- It separates warning red from Trumf red enough that warnings still feel like warnings.
- It supports dark mode with low-saturation surfaces instead of pure black cards.

## Alternative 1: Fjord Signal

| Role | HEX |
| --- | --- |
| Primary | `#0E5A60` |
| Background | `#F6F7F4` |
| Surface | `#FFFFFF` |
| Campaign | `#B66D12` |
| Warning | `#B23A24` |
| Success | `#177245` |
| EuroBonus | `#1C6797` |
| Trumf | `#B51D2D` |

Good for a slightly more premium and restrained app. Risk: primary can sit too close to EuroBonus blue in some contexts.

## Alternative 2: Clear Commerce

| Role | HEX |
| --- | --- |
| Primary | `#075F73` |
| Background | `#F5F8FA` |
| Surface | `#EAF2F5` |
| Campaign | `#D8791B` |
| Warning | `#C2412D` |
| Success | `#16805A` |
| EuroBonus | `#1F73A8` |
| Trumf | `#C22032` |

Good for a more energetic MVP. Risk: closer to common fintech and shopping palettes.

## Alternative 3: Graphite Trust

| Role | HEX |
| --- | --- |
| Primary | `#334155` |
| Background | `#F7F7F3` |
| Surface | `#ECEFEB` |
| Campaign | `#B7791F` |
| Warning | `#B42318` |
| Success | `#1F7A4D` |
| EuroBonus | `#256D9B` |
| Trumf | `#B51F31` |

Good if the app should feel more like a serious utility. Risk: too close to a slate-heavy interface, which can feel generic.

## Usage rules

- Primary is for app-level interaction, not every important number.
- Program colors should identify earning sources and combinations.
- Campaign is for time-limited opportunities only.
- Warning is for risk, uncertainty or "check this before purchase" messages.
- Success is for verified/editorial confidence, not for value or promotion.
- Soft colors should be used behind short labels and icons, not as large decorative blocks.
