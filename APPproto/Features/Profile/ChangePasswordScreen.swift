//
//  ChangePasswordScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct ChangePasswordScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: ChangePasswordViewModel
    @State private var saveRequested = false
    @State private var showSuccess = false

    init(api: any APIClient) {
        _model = State(
            initialValue: ChangePasswordViewModel(api: api)
        )
    }

    var body: some View {
        @Bindable var model = model

        ChangePasswordView(
            currentPassword: $model.currentPassword,
            newPassword: $model.newPassword,
            confirmation: $model.confirmation,
            isLoading: model.isLoading || saveRequested,
            canSubmit: model.canSubmit && !saveRequested,
            errorMessage: model.errorMessage,
            onSave: {
                saveRequested = true
            }
        )
        .navigationTitle(Text(verbatim: "Cambiar contraseña"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: saveRequested) {
            guard saveRequested else { return }

            let succeeded = await model.save()

            guard !Task.isCancelled else { return }

            showSuccess = succeeded
            saveRequested = false
        }
        .alert(
            Text(verbatim: "Contraseña actualizada"),
            isPresented: $showSuccess
        ) {
            Button {
                dismiss()
            } label: {
                Text(verbatim: "Aceptar")
            }
        } message: {
            Text(
                verbatim: "Contraseña actualizada. Cerramos tu sesión en los demás dispositivos."
            )
        }
        .onDisappear {
            saveRequested = false
            model.currentPassword = ""
            model.newPassword = ""
            model.confirmation = ""
        }
    }
}
