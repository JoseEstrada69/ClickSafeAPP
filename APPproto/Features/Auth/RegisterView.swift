//
//  RegisterView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

struct RegisterView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    @Binding var passwordConfirmation: String

    let isLoading: Bool
    let canSubmit: Bool
    let errorMessage: String?
    let onRegister: () -> Void

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                Text(verbatim: "Crear cuenta")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: Theme.Spacing.betweenBlocks) {
                    CSTextField(
                        title: "Nombre",
                        text: $name,
                        placeholder: "Escribe tu nombre"
                    )
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)

                    CSTextField(
                        title: "Correo electrónico",
                        text: $email,
                        placeholder: "Escribe tu correo"
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)

                    CSSecureField(
                        title: "Contraseña",
                        text: $password,
                        placeholder: "Crea tu contraseña"
                    )
                    .textContentType(.newPassword)
                    .submitLabel(.next)

                    Text(verbatim: "Usa entre 8 y 128 caracteres.")
                        .font(.footnote)
                        .foregroundStyle(Color.csTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    CSSecureField(
                        title: "Confirmar contraseña",
                        text: $passwordConfirmation,
                        placeholder: "Repite tu contraseña"
                    )
                    .textContentType(.newPassword)
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
                    title: "Crear cuenta",
                    isLoading: isLoading
                ) {
                    submit()
                }
                .disabled(!canSubmit)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground.ignoresSafeArea())
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }
        onRegister()
    }
}
