import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        Group {
            switch environment.loadState {
            case .idle where environment.programs.isEmpty:
                ProgressView("Henter muligheter")
            case .loading where environment.programs.isEmpty:
                ProgressView("Henter muligheter")
            case let .failed(message) where environment.programs.isEmpty:
                ContentUnavailableView(
                    "Kunne ikke laste data",
                    systemImage: "wifi.exclamationmark",
                    description: Text(message)
                )
            default:
                if environment.selectedFirstPhaseProgramIDs.isEmpty {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .task {
            await environment.loadIfNeeded()
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch environment.userSession.appearancePreference {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#Preview {
    RootView()
        .environment(AppEnvironment.mock())
}
