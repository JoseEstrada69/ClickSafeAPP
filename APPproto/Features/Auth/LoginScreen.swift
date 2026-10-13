//
//  LoginScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct LoginScreen: View {
    @State private var viewModel: LoginViewModel
    @State private var loginRequested = false
    @State private var showAdministratorAlert = false

    let onAuthenticated: (Me) -> Void
    let onVerificationRequired: (String) -> Void
    let onForgotPassword: () -> Void
    let onRegister: () -> Void

    init(
        api: any APIClient,
        tokenStore: TokenStore,
        email: String = "",
        onAuthenticated: @escaping (Me) -> Void,
        onVerificationRequired: @escaping (String) -> Void,
        onForgotPassword: @escaping () -> Void,
        onRegister: @escaping () -> Void
    ) {
        let model = LoginViewModel(
            api: api,
            tokenStore: tokenStore
        )
        model.email = email

        _viewModel = State(initialValue: model)

        self.onAuthenticated = onAuthenticated
        self.onVerificationRequired = onVerificationRequired
        self.onForgotPassword = onForgotPassword
        self.onRegister = onRegister
    }

    var body: some View {
        @Bindable var model = viewModel

        LoginView(
            email: $model.email,
            password: $model.password,
            isLoading: model.isLoading,
            canSubmit: model.canSubmit,
            errorMessage: model.errorMessage,
            onLogin: {
                guard !loginRequested else { return }
                loginRequested = true
            },
            onForgotPassword: onForgotPassword,
            onRegister: onRegister
        )
        .task(id: loginRequested) {
            guard loginRequested else { return }

            let outcome = await viewModel.login()

            loginRequested = false

            guard !Task.isCancelled, let outcome else {
                return
            }

            switch outcome {
            case .authenticated(let user):
                onAuthenticated(user)

            case .verificationRequired(let correo):
                onVerificationRequired(correo)

            case .administratorAccount:
                showAdministratorAlert = true
            }
        }
        .onDisappear {
            loginRequested = false
            viewModel.password = ""
        }
        .alert(
            Text(verbatim: "Cuenta de administrador"),
            isPresented: $showAdministratorAlert
        ) {
            Button {
                showAdministratorAlert = false
            } label: {
                Text(verbatim: "Aceptar")
            }
        } message: {
            Text(
                verbatim: """
                Las cuentas de administrador se usan desde el panel web de ClickSafe.
                """
            )
        }
    }
}
