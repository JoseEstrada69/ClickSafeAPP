//
//  ForgotPasswordScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct ForgotPasswordScreen: View {
    private enum Operation {
        case requestCode
        case resetPassword
    }

    @State private var viewModel: ForgotPasswordViewModel
    @State private var operation: Operation?
    @State private var showSuccessAlert = false
    @State private var recoveredEmail = ""

    let onPasswordReset: (String) -> Void

    init(
        api: any APIClient,
        onPasswordReset: @escaping (String) -> Void
    ) {
        _viewModel = State(
            initialValue: ForgotPasswordViewModel(api: api)
        )

        self.onPasswordReset = onPasswordReset
    }

    var body: some View {
        @Bindable var model = viewModel

        ForgotPasswordView(
            email: $model.email,
            code: $model.code,
            newPassword: $model.newPassword,
            passwordConfirmation: $model.passwordConfirmation,
            isResetStep: model.isResetStep,
            isLoading: model.isLoading || operation != nil,
            canSubmit: model.canSubmit && operation == nil,
            errorMessage: model.errorMessage,
            onRequestCode: {
                guard operation == nil else { return }
                operation = .requestCode
            },
            onResetPassword: {
                guard operation == nil else { return }
                operation = .resetPassword
            }
        )
        .disabled(showSuccessAlert)
        .task(id: operation) {
            guard let requestedOperation = operation else {
                return
            }

            switch requestedOperation {
            case .requestCode:
                await viewModel.requestCode()

                guard !Task.isCancelled else { return }

            case .resetPassword:
                let correo = await viewModel.resetPassword()

                guard !Task.isCancelled else { return }

                if let correo {
                    recoveredEmail = correo
                    showSuccessAlert = true
                }
            }

            operation = nil
        }
        .onDisappear {
            operation = nil
            viewModel.code = ""
            viewModel.newPassword = ""
            viewModel.passwordConfirmation = ""
        }
        .alert(
            Text(verbatim: "Contraseña actualizada"),
            isPresented: $showSuccessAlert
        ) {
            Button {
                onPasswordReset(recoveredEmail)
            } label: {
                Text(verbatim: "Iniciar sesión")
            }
        } message: {
            Text(verbatim: "Contraseña actualizada. Inicia sesión de nuevo.")
        }
    }
}
