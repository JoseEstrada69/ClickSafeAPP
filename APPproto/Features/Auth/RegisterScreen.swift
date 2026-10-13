//
//  RegisterScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct RegisterScreen: View {
    @State private var viewModel: RegisterViewModel
    @State private var registrationRequested = false

    let onVerificationRequired: (String) -> Void
    let onLogin: () -> Void

    init(
        api: any APIClient,
        onVerificationRequired: @escaping (String) -> Void,
        onLogin: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: RegisterViewModel(api: api)
        )

        self.onVerificationRequired = onVerificationRequired
        self.onLogin = onLogin
    }

    var body: some View {
        @Bindable var model = viewModel

        VStack(spacing: 0) {
            RegisterView(
                name: $model.name,
                email: $model.email,
                password: $model.password,
                passwordConfirmation: $model.passwordConfirmation,
                isLoading: model.isLoading,
                canSubmit: model.canSubmit,
                errorMessage: model.errorMessage,
                onRegister: {
                    guard !registrationRequested else { return }
                    registrationRequested = true
                }
            )

            Button(action: onLogin) {
                Text(verbatim: "¿Ya tienes una cuenta? Inicia sesión")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: Theme.Size.minimumTouchTarget
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.csNavy)
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .disabled(model.isLoading || registrationRequested)
        }
        .background(Color.csBackground.ignoresSafeArea())
        .task(id: registrationRequested) {
            guard registrationRequested else { return }

            let correo = await viewModel.register()

            registrationRequested = false

            guard !Task.isCancelled, let correo else {
                return
            }

            onVerificationRequired(correo)
        }
        .onDisappear {
            registrationRequested = false
            viewModel.password = ""
            viewModel.passwordConfirmation = ""
        }
    }
}
