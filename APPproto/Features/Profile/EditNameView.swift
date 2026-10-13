//
//  EditNameView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

struct EditNameView: View {
    @Binding var name: String

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
                Text(verbatim: "Editar nombre")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                CSTextField(
                    title: "Nombre",
                    text: $name,
                    placeholder: "Escribe tu nombre"
                )
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .disabled(isLoading)
                .onSubmit {
                    submit()
                }

                Text(verbatim: "Usa entre 1 y 100 caracteres.")
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)

                if let errorMessage {
                    Text(verbatim: errorMessage)
                        .font(.callout)
                        .foregroundStyle(Color.csDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LoadingButton(
                    title: "Guardar cambios",
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
        onSave()
    }
}
