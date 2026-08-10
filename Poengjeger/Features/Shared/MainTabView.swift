import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label("Kampanjer", systemImage: "safari")
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
                Label("Profil", systemImage: "person")
            }
        }
        .tint(PoengjegerTheme.accent)
    }
}
