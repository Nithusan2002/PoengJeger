import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        Group {
            switch environment.loadState {
            case .idle where environment.programs.isEmpty:
                ProgressView("Henter kampanjer")
            case .loading where environment.programs.isEmpty:
                ProgressView("Henter kampanjer")
            case let .failed(message) where environment.programs.isEmpty:
                ContentUnavailableView(
                    "Kunne ikke laste data",
                    systemImage: "wifi.exclamationmark",
                    description: Text(message)
                )
            default:
                if environment.userSession.selectedProgramIDs.isEmpty {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            }
        }
        .task {
            await environment.loadIfNeeded()
        }
    }
}

#Preview {
    RootView()
        .environment(AppEnvironment.bootstrap())
}
