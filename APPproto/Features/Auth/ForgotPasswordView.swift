//
//  ForgotPasswordView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Binding var email: String
    @Binding var code: String
    @Binding var newPassword: String
    @Binding var passwordConfirmation: String

    let isResetStep: Bool
    let isLoading: Bool
    let canSubmit: Bool
    let errorMessage: String?

    let onRequestCode: () -> Void
    let onResetPassword: () -> Void

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                Text(verbatim: "Recuperar contraseña")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                if isResetStep {
                    resetFields
                } else {
                    requestFields
                }

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.callout)
                        .foregroundStyle(Color.csDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LoadingButton(
                    title: isResetStep
                        ? "Actualizar contraseña"
                        : "Enviar código",
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

    private var requestFields: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.betweenBlocks
        ) {
            Text(verbatim: "Escribe tu correo para recuperar el acceso.")
                .font(.body)
                .foregroundStyle(Color.csTextSecondary)

            CSTextField(
                title: "Correo electrónico",
                text: $email,
                placeholder: "Escribe tu correo"
            )
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .onSubmit {
                submit()
            }
        }
        .disabled(isLoading)
    }

    private var resetFields: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.betweenBlocks
        ) {
            Text(
                verbatim: """
                Si el correo está registrado, recibirás un código de 8 dígitos.
                """
            )
            .font(.body)
            .foregroundStyle(Color.csTextSecondary)
            .fixedSize(horizontal: false, vertical: true)

            CSTextField(
                title: "Código de recuperación",
                text: $code,
                placeholder: "8 dígitos"
            )
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .onChange(of: code) { _, newValue in
                let filtered = String(
                    newValue.filter {
                        "0123456789".contains($0)
                    }.prefix(8)
                )

                if code != filtered {
                    code = filtered
                }
            }

            CSSecureField(
                title: "Nueva contraseña",
                text: $newPassword,
                placeholder: "Crea tu nueva contraseña"
            )
            .textContentType(.newPassword)
            .submitLabel(.next)

            Text(verbatim: "Usa entre 8 y 128 caracteres.")
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)

            CSSecureField(
                title: "Confirmar contraseña",
                text: $passwordConfirmation,
                placeholder: "Repite tu nueva contraseña"
            )
            .textContentType(.newPassword)
            .submitLabel(.go)
            .onSubmit {
                submit()
            }
        }
        .disabled(isLoading)
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }

        if isResetStep {
            onResetPassword()
        } else {
            onRequestCode()
        }
    }
}
