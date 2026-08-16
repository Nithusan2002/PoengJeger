import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label("Nå", systemImage: "clock")
            }

            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label("Lær", systemImage: "graduationcap")
            }

            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Lagret", systemImage: "bookmark")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Innstillinger", systemImage: "gearshape")
            }
        }
        .tint(PoengjegerTheme.accent)
    }
}
