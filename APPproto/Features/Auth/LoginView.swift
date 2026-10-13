//
//  LoginView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

struct LoginView: View {
    @Binding var email: String
    @Binding var password: String

    let isLoading: Bool
    let canSubmit: Bool
    let errorMessage: String?

    let onLogin: () -> Void
    let onForgotPassword: () -> Void
    let onRegister: () -> Void

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                Text(verbatim: "Iniciar sesión")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: Theme.Spacing.betweenBlocks) {
                    CSTextField(
                        title: "Correo electrónico",
                        text: $email,
                        placeholder: "Escribe tu correo"
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)

                    CSSecureField(
                        title: "Contraseña",
                        text: $password,
                        placeholder: "Escribe tu contraseña"
                    )
                    .textContentType(.password)
                    .submitLabel(.go)
                    .onSubmit {
                        submit()
                    }
                }
                .disabled(isLoading)

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.callout)
                        .foregroundStyle(Color.csDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LoadingButton(
                    title: "Iniciar sesión",
                    isLoading: isLoading
                ) {
                    submit()
                }
                .disabled(!canSubmit)

                Button(action: onForgotPassword) {
                    Text(verbatim: "¿Olvidaste tu contraseña?")
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
                .disabled(isLoading)

                SecondaryButton(
                    title: "Crear cuenta",
                    action: onRegister
                )
                .disabled(isLoading)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground.ignoresSafeArea())
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }
        onLogin()
    }
}

private struct LoginViewPreview: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        LoginView(
            email: $email,
            password: $password,
            isLoading: false,
            canSubmit: false,
            errorMessage: nil,
            onLogin: {},
            onForgotPassword: {},
            onRegister: {}
        )
    }
}

#Preview("Claro") {
    LoginViewPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    LoginViewPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    LoginViewPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
