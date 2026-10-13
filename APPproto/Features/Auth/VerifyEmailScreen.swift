//
//  VerifyEmailScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct VerifyEmailScreen: View {
    private enum Operation {
        case verify
        case resend
    }

    @State private var viewModel: VerifyEmailViewModel
    @State private var operation: Operation?
    @State private var showSuccessAlert = false

    let onVerified: (String) -> Void

    init(
        email: String,
        api: any APIClient,
        onVerified: @escaping (String) -> Void
    ) {
        _viewModel = State(
            initialValue: VerifyEmailViewModel(
                email: email,
                api: api
            )
        )

        self.onVerified = onVerified
    }

    var body: some View {
        @Bindable var model = viewModel

        VerifyEmailView(
            email: model.email,
            code: $model.code,
            isLoading: model.isLoading || operation != nil,
            canSubmit: model.canSubmit && operation == nil,
            resendSecondsRemaining: model.resendSecondsRemaining,
            errorMessage: model.errorMessage,
            onVerify: {
                guard operation == nil else { return }
                operation = .verify
            },
            onResend: {
                guard operation == nil else { return }
                operation = .resend
            }
        )
        .disabled(showSuccessAlert)
        .task {
            await viewModel.runCountdown()
        }
        .task(id: operation) {
            guard let requestedOperation = operation else {
                return
            }

            switch requestedOperation {
            case .verify:
                let verified = await viewModel.verify()

                guard !Task.isCancelled else { return }

                if verified {
                    showSuccessAlert = true
                }

            case .resend:
                await viewModel.resend()

                guard !Task.isCancelled else { return }
            }

            operation = nil
        }
        .onDisappear {
            operation = nil
            viewModel.code = ""
        }
        .alert(
            Text(verbatim: "¡Cuenta verificada!"),
            isPresented: $showSuccessAlert
        ) {
            Button {
                onVerified(viewModel.email)
            } label: {
                Text(verbatim: "Iniciar sesión")
            }
        } message: {
            Text(verbatim: "Tu cuenta está lista. Inicia sesión para continuar.")
        }
    }
}
