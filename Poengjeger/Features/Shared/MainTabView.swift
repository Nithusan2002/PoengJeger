import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label("Feed", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Favoritter", systemImage: "star")
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
