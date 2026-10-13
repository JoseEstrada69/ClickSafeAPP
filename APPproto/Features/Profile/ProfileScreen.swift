//
//  ProfileScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct ProfileScreen: View {
    private enum Route: Hashable {
        case myReports
        case editName
        case changePassword
    }

    @Environment(AppState.self) private var appState
    @State private var path = NavigationPath()

    let api: any APIClient

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let user = appState.currentUser {
                    ProfileView(
                        user: user,
                        isLoggingOut: appState.isLoggingOut,
                        onMyReports: {
                            path.append(Route.myReports)
                        },
                        onEditName: {
                            path.append(Route.editName)
                        },
                        onChangePassword: {
                            path.append(Route.changePassword)
                        },
                        onLogout: { everywhere in
                            Task {
                                await appState.logout(
                                    everywhere: everywhere
                                )
                            }
                        }
                    )
                }
            }
            .navigationDestination(
                for: Route.self
            ) { destination in
                switch destination {
                case .myReports:
                    MyReportsScreen(api: api)

                case .editName:
                    if let user = appState.currentUser {
                        EditNameScreen(
                            name: user.nombre,
                            api: api,
                            onSaved: { updatedUser in
                                appState.updateCurrentUser(updatedUser)
                            }
                        )
                    }

                case .changePassword:
                    ChangePasswordScreen(api: api)
                }
            }
            .navigationDestination(
                for: MyReportsRoute.self
            ) { destination in
                switch destination {
                case .reportDetail(let reportID):
                    ReportDetailScreen(
                        reportID: reportID,
                        api: api
                    )
                }
            }
        }
    }
}
