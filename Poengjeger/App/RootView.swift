import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        if environment.userSession.selectedProgramIDs.isEmpty {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

#Preview {
    RootView()
        .environment(AppEnvironment.bootstrap())
}
