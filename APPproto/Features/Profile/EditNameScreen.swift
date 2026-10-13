//
//  EditNameScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct EditNameScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: EditNameViewModel
    @State private var saveRequested = false

    let onSaved: (Me) -> Void

    init(
        name: String,
        api: any APIClient,
        onSaved: @escaping (Me) -> Void
    ) {
        _viewModel = State(
            initialValue: EditNameViewModel(
                name: name,
                api: api
            )
        )

        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var model = viewModel

        EditNameView(
            name: $model.name,
            isLoading: model.isLoading || saveRequested,
            canSubmit: model.canSubmit && !saveRequested,
            errorMessage: model.errorMessage,
            onSave: {
                guard !saveRequested else { return }
                saveRequested = true
            }
        )
        .navigationTitle(Text(verbatim: "Editar nombre"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: saveRequested) {
            guard saveRequested else { return }

            let user = await viewModel.save()

            guard !Task.isCancelled else { return }

            if let user {
                onSaved(user)
                dismiss()
            }

            saveRequested = false
        }
        .onDisappear {
            saveRequested = false
        }
    }
}
