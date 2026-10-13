//
//  AppState.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    enum SessionState {
        case loading
        case loggedOut
        case loggedIn
    }

    private(set) var sessionState: SessionState = .loading
    private(set) var currentUser: Me?
    private(set) var sessionMessage: String?
    private(set) var sessionID = UUID()
    private(set) var isLoggingOut = false

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private let tokenStore: TokenStore

    @ObservationIgnored
    private let defaults: UserDefaults

    @ObservationIgnored
    private var hasStarted = false

    @ObservationIgnored
    private var revision = UUID()

    init(
        api: any APIClient,
        tokenStore: TokenStore,
        defaults: UserDefaults = .standard
    ) {
        self.api = api
        self.tokenStore = tokenStore
        self.defaults = defaults
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        let operationID = revision

        do {
            if !defaults.bool(forKey: "hasLaunchedBefore") {
                try await tokenStore.clear()

                guard revision == operationID else { return }

                defaults.set(true, forKey: "hasLaunchedBefore")
                showLoggedOut()
                return
            }

            guard try await tokenStore.hasRefreshToken() else {
                guard revision == operationID else { return }
                showLoggedOut()
                return
            }

            guard revision == operationID else { return }

            let user: Me = try await api.send(
                Endpoint(path: "me"),
                expecting: Me.self
            )

            guard revision == operationID else { return }

            showLoggedIn(user)
        } catch is CancellationError {
            guard revision == operationID else { return }

            hasStarted = false
            sessionMessage = nil
        } catch {
            guard revision == operationID else { return }

            do {
                try await tokenStore.clear()

                guard revision == operationID else { return }

                showLoggedOut()
            } catch {
                guard revision == operationID else { return }

                showLoggedOut(
                    message: """
                    No se pudo limpiar la sesión guardada. Intenta de nuevo.
                    """
                )
            }
        }
    }

    func didAuthenticate(_ user: Me) {
        guard !isLoggingOut else { return }

        revision = UUID()
        showLoggedIn(user)
    }

    func updateCurrentUser(_ user: Me) {
        guard case .loggedIn = sessionState,
              !isLoggingOut,
              currentUser?.correo == user.correo else {
            return
        }

        currentUser = user
    }

    func logout(everywhere: Bool = false) async {
        guard !isLoggingOut else { return }

        isLoggingOut = true
        revision = UUID()

        defer {
            isLoggingOut = false
        }

        var serverLogoutFailed = false

        if case .loggedIn = sessionState {
            do {
                try await api.sendWithoutResponse(
                    Endpoint(
                        path: everywhere
                            ? "auth/logout-all"
                            : "auth/logout",
                        method: .post
                    )
                )
            } catch {
                serverLogoutFailed = true
            }
        }

        await clearLocalSession(
            message: serverLogoutFailed
                ? """
                La sesión se cerró en este dispositivo, pero no se pudo confirmar el cierre en el servidor.
                """
                : nil
        )
    }

    func sessionExpired() async {
        revision = UUID()

        await clearLocalSession(
            message: "Tu sesión expiró. Inicia sesión de nuevo."
        )
    }

    private func clearLocalSession(message: String?) async {
        currentUser = nil
        sessionState = .loggedOut
        sessionMessage = message
        sessionID = UUID()

        URLCache.shared.removeAllCachedResponses()

        do {
            try await tokenStore.clear()
        } catch {
            sessionMessage = """
            No se pudo limpiar la sesión guardada. Intenta cerrar sesión de nuevo.
            """
        }
    }

    private func showLoggedIn(_ user: Me) {
        currentUser = user
        sessionMessage = nil
        sessionID = UUID()
        sessionState = .loggedIn
    }

    private func showLoggedOut(message: String? = nil) {
        currentUser = nil
        sessionMessage = message
        sessionID = UUID()
        sessionState = .loggedOut
    }
}
