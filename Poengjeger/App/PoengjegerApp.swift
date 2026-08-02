import SwiftUI

@main
struct PoengjegerApp: App {
    @State private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
    }
}
