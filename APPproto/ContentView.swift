//
//  ContentView.swift
//  APPproto
//
//  Created by alumno on 04/09/26.
//

import SwiftUI

@MainActor
struct ContentView: View {
    private struct Runtime {
        let appState: AppState
        let api: any APIClient
        let tokenStore: TokenStore
    }

    let configuration: AppConfig

    @State private var runtime: Runtime?
    @State private var initializationFailed = false

    var body: some View {
        Group {
            if let runtime {
                RootView {
                    AuthFlowView(
                        api: runtime.api,
                        tokenStore: runtime.tokenStore,
                        onAuthenticated: { user in
                            runtime.appState.didAuthenticate(user)
                        }
                    )
                } loggedIn: {
                    MainTabView(api: runtime.api)
                }
                .environment(runtime.appState)
                .environment(
                    \.evidenceBaseURL,
                    configuration.apiBaseURL
                )
                .environment(
                    \.mockEvidenceImagesEnabled,
                    configuration.useMockAPI
                )
            } else if initializationFailed {
                ContentUnavailableView {
                    Label {
                        Text(verbatim: "No se pudo iniciar ClickSafe")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                } description: {
                    Text(
                        verbatim: "La configuración de la app no es válida."
                    )
                }
            } else {
                ProgressView()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            }
        }
        .task {
            await initializeSession()
        }
    }

    private func initializeSession() async {
        guard runtime == nil, !initializationFailed else {
            return
        }

        let tokenStore = TokenStore()
        let expirationHandler = SessionExpirationHandler()
        let api: any APIClient

        if configuration.useMockAPI {
            api = await MockAuthAPIClient()
        } else {
            guard let baseURL = configuration.apiBaseURL else {
                initializationFailed = true
                return
            }

            api = LiveAPIClient(
                baseURL: baseURL,
                tokenStore: tokenStore,
                onSessionExpired: {
                    await expirationHandler.handleExpiration()
                }
            )
        }

        guard !Task.isCancelled else {
            return
        }

        let appState = AppState(
            api: api,
            tokenStore: tokenStore
        )

        expirationHandler.appState = appState

        runtime = Runtime(
            appState: appState,
            api: api,
            tokenStore: tokenStore
        )
    }
}

@MainActor
private final class SessionExpirationHandler {
    weak var appState: AppState?

    func handleExpiration() async {
        await appState?.sessionExpired()
    }
}
