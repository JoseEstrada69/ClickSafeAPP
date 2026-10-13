//
//  ChangePasswordView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

struct ChangePasswordView: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmation: String

    let isLoading: Bool
    let canSubmit: Bool
    let errorMessage: String?
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                CSSecureField(
                    title: "Contraseña actual",
                    text: $currentPassword,
                    placeholder: "Escribe tu contraseña actual"
                )
                .textContentType(.password)

                CSSecureField(
                    title: "Nueva contraseña",
                    text: $newPassword,
                    placeholder: "Escribe tu nueva contraseña"
                )
                .textContentType(.newPassword)

                Text(verbatim: "Usa entre 8 y 128 caracteres.")
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)

                CSSecureField(
                    title: "Confirmar nueva contraseña",
                    text: $confirmation,
                    placeholder: "Repite tu nueva contraseña",
                    errorMessage: confirmationError
                )
                .textContentType(.newPassword)
                .submitLabel(.done)
                .onSubmit {
                    submit()
                }

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.callout)
                        .foregroundStyle(Color.csDanger)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                PrimaryButton(
                    title: isLoading
                        ? "Guardando…"
                        : "Guardar cambios"
                ) {
                    submit()
                }
                .disabled(!canSubmit || isLoading)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(
                            Text(verbatim: "Actualizando contraseña")
                        )
                }
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .disabled(isLoading)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground.ignoresSafeArea())
    }

    private var confirmationError: String? {
        guard !confirmation.isEmpty,
              confirmation != newPassword else {
            return nil
        }

        return "Las contraseñas no coinciden."
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }
        onSave()
    }
}
