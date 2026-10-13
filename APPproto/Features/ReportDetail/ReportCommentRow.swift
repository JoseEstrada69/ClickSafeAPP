//
//  ReportCommentRow.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct ReportCommentRow: View {
    let comment: Comment
    let onDeleted: () async -> Void

    private let api: any APIClient

    @State private var model: DeleteCommentViewModel
    @State private var showsDeleteConfirmation = false
    @State private var showsFlagScreen = false
    @State private var deleteRequested = false

    init(
        comment: Comment,
        api: any APIClient,
        onDeleted: @escaping () async -> Void
    ) {
        self.comment = comment
        self.api = api
        self.onDeleted = onDeleted

        _model = State(
            initialValue: DeleteCommentViewModel(api: api)
        )
    }

    private var authorName: String {
        comment.anonimo
            ? "Usuario anónimo"
            : comment.autor?.nombre ?? "Usuario"
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.unitsStyle = .abbreviated

        return formatter.localizedString(
            for: comment.fechaCreacion,
            relativeTo: Date()
        )
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard
        ) {
            HStack(alignment: .top) {
                Text(verbatim: authorName)
                    .font(.headline)
                    .foregroundStyle(Color.csTextPrimary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                Menu {
                    commentActions
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .foregroundStyle(Color.csNavy)
                        .frame(
                            minWidth: Theme.Size.minimumTouchTarget,
                            minHeight: Theme.Size.minimumTouchTarget
                        )
                        .contentShape(Rectangle())
                }
                .disabled(model.isDeleting || deleteRequested)
                .accessibilityLabel(
                    Text(verbatim: "Opciones del comentario")
                )
            }

            Text(verbatim: comment.contenido)
                .font(.body)
                .foregroundStyle(Color.csTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(verbatim: relativeDate)
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)

            if model.isDeleting || deleteRequested {
                ProgressView()
                    .accessibilityLabel(
                        Text(verbatim: "Borrando comentario")
                    )
            }

            if let message = model.errorMessage {
                ErrorBanner(message: message) {
                    showsDeleteConfirmation = true
                }
                .disabled(model.isDeleting || deleteRequested)
            }
        }
        .padding(.vertical, Theme.Spacing.withinCard)
        .contextMenu {
            commentActions
        }
        .confirmationDialog(
            Text(verbatim: "¿Borrar este comentario?"),
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                deleteRequested = true
            } label: {
                Text(verbatim: "Borrar comentario")
            }

            Button(role: .cancel) {
            } label: {
                Text(verbatim: "Cancelar")
            }
        } message: {
            Text(verbatim: "Esta acción no se puede deshacer.")
        }
        .sheet(isPresented: $showsFlagScreen) {
            CommentFlagScreen(comment: comment, api: api)
        }
        .task(id: deleteRequested) {
            guard deleteRequested else {
                return
            }

            if await model.delete(comment) {
                await onDeleted()
            }

            guard !Task.isCancelled else {
                return
            }

            deleteRequested = false
        }
        .onDisappear {
            showsDeleteConfirmation = false
            deleteRequested = false
        }
    }

    @ViewBuilder
    private var commentActions: some View {
        if comment.esMio {
            Button(role: .destructive) {
                showsDeleteConfirmation = true
            } label: {
                Label {
                    Text(verbatim: "Borrar")
                } icon: {
                    Image(systemName: "trash")
                }
            }
            .disabled(model.isDeleting || deleteRequested)
        } else {
            Button {
                showsFlagScreen = true
            } label: {
                Label {
                    Text(verbatim: "Denunciar")
                } icon: {
                    Image(systemName: "flag")
                }
            }
        }
    }
}
