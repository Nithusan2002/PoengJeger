import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Hjem", systemImage: "house")
            }

            NavigationStack {
                ExploreView()
            }
            .tabItem {
                Label("Utforsk", systemImage: "magnifyingglass")
            }

            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label("Guider", systemImage: "graduationcap")
            }

            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Lagret", systemImage: "star")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.crop.circle")
            }
        }
        .tint(PoengjegerTheme.primary)
    }
}
