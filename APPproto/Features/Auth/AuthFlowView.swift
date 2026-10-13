//
//  AuthFlowView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct AuthFlowView: View {
    @State private var path: [Route] = []
    @State private var loginEmail = ""

    let api: any APIClient
    let tokenStore: TokenStore
    let onAuthenticated: (Me) -> Void

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onLogin: {
                    loginEmail = ""
                    path.append(.login)
                },
                onRegister: {
                    path.append(.register)
                }
            )
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .login:
            LoginScreen(
                api: api,
                tokenStore: tokenStore,
                email: loginEmail,
                onAuthenticated: onAuthenticated,
                onVerificationRequired: { correo in
                    path.append(.verifyEmail(correo: correo))
                },
                onForgotPassword: {
                    path.append(.forgotPassword)
                },
                onRegister: {
                    path.append(.register)
                }
            )
            .id(loginEmail)
            .navigationTitle(Text(verbatim: "Iniciar sesión"))
            .navigationBarTitleDisplayMode(.inline)

        case .register:
            RegisterScreen(
                api: api,
                onVerificationRequired: { correo in
                    path.append(.verifyEmail(correo: correo))
                },
                onLogin: {
                    openLogin(email: "")
                }
            )
            .navigationTitle(Text(verbatim: "Crear cuenta"))
            .navigationBarTitleDisplayMode(.inline)

        case .verifyEmail(let correo):
            VerifyEmailScreen(
                email: correo,
                api: api,
                onVerified: { verifiedEmail in
                    openLogin(email: verifiedEmail)
                }
            )
            .navigationTitle(Text(verbatim: "Verificar correo"))
            .navigationBarTitleDisplayMode(.inline)

        case .forgotPassword:
            ForgotPasswordScreen(
                api: api,
                onPasswordReset: { recoveredEmail in
                    openLogin(email: recoveredEmail)
                }
            )
            .navigationTitle(Text(verbatim: "Recuperar contraseña"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func openLogin(email: String) {
        loginEmail = email
        path = [.login]
    }
}
