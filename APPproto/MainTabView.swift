//
//  MainTabView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

@MainActor
struct MainTabView: View {
    private enum Tab: Hashable {
        case home
        case search
        case report
        case profile
    }

    let api: any APIClient

    @Environment(AppState.self) private var appState

    @State private var selectedTab: Tab = .home
    @State private var homePath: [ReportSearchRoute] = []
    @State private var searchFocusRequest: UUID?
    @State private var reportPublicationURL = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $homePath) {
                HomeScreen(
                    api: api,
                    onSearch: openSearch,
                    onReportPublication: openReport
                )
            }
            .tabItem {
                Label {
                    Text(verbatim: "Inicio")
                } icon: {
                    Image(systemName: "house")
                }
            }
            .tag(Tab.home)

            ReportSearchScreen(
                api: api,
                focusRequest: searchFocusRequest,
                onReportPublication: openReport
            )
            .tabItem {
                Label {
                    Text(verbatim: "Buscar")
                } icon: {
                    Image(systemName: "magnifyingglass")
                }
            }
            .tag(Tab.search)

            ReportCreationFlowView(
                api: api,
                publicationURL: $reportPublicationURL,
                onReturnHome: {
                    selectedTab = .home
                }
            )
            .tabItem {
                Label {
                    Text(verbatim: "Reportar")
                } icon: {
                    Image(systemName: "plus.circle")
                }
            }
            .tag(Tab.report)

            ProfileScreen(api: api)
                .tabItem {
                    Label {
                        Text(verbatim: "Perfil")
                    } icon: {
                        Image(systemName: "person.crop.circle")
                    }
                }
                .tag(Tab.profile)
        }
        .tint(Color.csNavy)
        .disabled(appState.isLoggingOut)
    }

    private func openSearch() {
        searchFocusRequest = UUID()
        selectedTab = .search
    }

    private func openReport(_ publicationURL: String?) {
        homePath.removeAll()
        reportPublicationURL = publicationURL ?? ""
        selectedTab = .report
    }
}
