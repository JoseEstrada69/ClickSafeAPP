//
//  DeleteReportButton.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct DeleteReportButton: View {
    let report: Report
    let onEdited: () async -> Void

    private let api: any APIClient

    @Environment(\.dismiss) private var dismiss

    @State private var model: DeleteReportViewModel
    @State private var showsConfirmation = false
    @State private var showsEditor = false
    @State private var deleteRequested = false
    @State private var showsError = false

    init(
        report: Report,
        api: any APIClient,
        onEdited: @escaping () async -> Void = {}
    ) {
        self.report = report
        self.api = api
        self.onEdited = onEdited

        _model = State(
            initialValue: DeleteReportViewModel(api: api)
        )
    }

    var body: some View {
        Group {
            if report.esMio, report.estado == .pending {
                Menu {
                    Button {
                        showsEditor = true
                    } label: {
                        Label {
                            Text(verbatim: "Editar")
                        } icon: {
                            Image(systemName: "pencil")
                        }
                    }

                    Button(role: .destructive) {
                        showsConfirmation = true
                    } label: {
                        Label {
                            Text(verbatim: "Borrar reporte")
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                } label: {
                    Group {
                        if model.isDeleting || deleteRequested {
                            ProgressView()
                        } else {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    .frame(
                        minWidth: Theme.Size.minimumTouchTarget,
                        minHeight: Theme.Size.minimumTouchTarget
                    )
                }
                .disabled(model.isDeleting || deleteRequested)
                .accessibilityLabel(
                    Text(verbatim: "Opciones de tu reporte")
                )
            }
        }
        .sheet(isPresented: $showsEditor) {
            NavigationStack {
                ReportEditScreen(
                    report: report,
                    api: api,
                    onSaved: { _ in
                        await onEdited()
                    }
                )
            }
        }
        .confirmationDialog(
            Text(verbatim: "¿Borrar este reporte?"),
            isPresented: $showsConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                deleteRequested = true
            } label: {
                Text(verbatim: "Borrar reporte")
            }

            Button(role: .cancel) {
            } label: {
                Text(verbatim: "Cancelar")
            }
        } message: {
            Text(verbatim: "Esta acción no se puede deshacer.")
        }
        .alert(
            Text(verbatim: "No se pudo borrar el reporte"),
            isPresented: $showsError
        ) {
            Button {
                showsConfirmation = true
            } label: {
                Text(verbatim: "Reintentar")
            }

            Button(role: .cancel) {
            } label: {
                Text(verbatim: "Cancelar")
            }
        } message: {
            Text(verbatim: model.errorMessage ?? "")
        }
        .task(id: deleteRequested) {
            guard deleteRequested else {
                return
            }

            let deleted = await model.delete(report)

            guard !Task.isCancelled else {
                return
            }

            deleteRequested = false

            if deleted {
                dismiss()
            } else {
                showsError = model.errorMessage != nil
            }
        }
        .onDisappear {
            showsConfirmation = false
            deleteRequested = false
        }
    }
}
