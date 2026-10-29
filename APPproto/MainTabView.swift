import SwiftUI

@MainActor
struct MainTabView: View {
    private enum Tab: Hashable { case home, search, report, profile }
    @State private var selectedTab: Tab = .home
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Inicio", systemImage: "house") }
            .tag(Tab.home)
            NavigationStack {
                Color.clear.navigationTitle(Text(verbatim: "Buscar"))
            }
            .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
            .tag(Tab.search)
            NavigationStack {
                Color.clear.navigationTitle(Text(verbatim: "Reportar"))
            }
            .tabItem { Label("Reportar", systemImage: "plus.circle") }
            .tag(Tab.report)
            NavigationStack {
                Color.clear.navigationTitle(Text(verbatim: "Perfil"))
            }
            .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
            .tag(Tab.profile)
        }
        .tint(Color.csNavy)
    }
}
