//
//  VerifyEmailView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

struct VerifyEmailView: View {
    let email: String

    @Binding var code: String

    let isLoading: Bool
    let canSubmit: Bool
    let resendSecondsRemaining: Int
    let errorMessage: String?

    let onVerify: () -> Void
    let onResend: () -> Void

    private var resendTitle: String {
        guard resendSecondsRemaining > 0 else {
            return "Reenviar código"
        }

        let minutes = resendSecondsRemaining / 60
        let seconds = resendSecondsRemaining % 60
        let formattedSeconds = String(format: "%02d", seconds)

        return "Reenviar en \(minutes):\(formattedSeconds)"
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                Text(verbatim: "Verificar correo")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(
                    verbatim: """
                    Enviamos un código de 6 dígitos a \(email). \
                    Escríbelo para activar tu cuenta.
                    """
                )
                .font(.body)
                .foregroundStyle(Color.csTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

                CSTextField(
                    title: "Código de verificación",
                    text: $code,
                    placeholder: "6 dígitos"
                )
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .disabled(isLoading)
                .onChange(of: code) { _, newValue in
                    let filtered = String(
                        newValue.filter {
                            "0123456789".contains($0)
                        }.prefix(6)
                    )

                    if code != filtered {
                        code = filtered
                    }
                }

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.callout)
                        .foregroundStyle(Color.csDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LoadingButton(
                    title: "Verificar",
                    isLoading: isLoading
                ) {
                    guard canSubmit, !isLoading else { return }
                    onVerify()
                }
                .disabled(!canSubmit)

                SecondaryButton(title: resendTitle) {
                    guard !isLoading,
                          resendSecondsRemaining == 0 else {
                        return
                    }

                    onResend()
                }
                .disabled(
                    isLoading || resendSecondsRemaining > 0
                )
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground.ignoresSafeArea())
    }
}
