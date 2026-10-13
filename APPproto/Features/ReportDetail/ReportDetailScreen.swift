//
//  ReportDetailScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct ReportDetailScreen: View {
    private let api: any APIClient

    @State private var model: ReportDetailViewModel
    @State private var commentsModel: ReportCommentsViewModel
    @State private var composerModel: CommentComposerViewModel
    @State private var likeModel: ReportLikeViewModel?
    @State private var retryReportRequested = false
    @State private var retryCommentsRequested = false

    init(reportID: Int, api: any APIClient) {
        self.api = api

        _model = State(
            initialValue: ReportDetailViewModel(
                reportID: reportID,
                api: api
            )
        )

        _commentsModel = State(
            initialValue: ReportCommentsViewModel(
                reportID: reportID,
                api: api
            )
        )

        _composerModel = State(
            initialValue: CommentComposerViewModel(
                reportID: reportID,
                api: api
            )
        )
    }

    var body: some View {
        List {
            if model.report == nil, model.errorMessage == nil {
                loadingRow("Cargando reporte")
            }

            if let report = model.report {
                Section {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.Spacing.withinCard
                    ) {
                        Text(verbatim: report.titulo)
                            .font(.title3.bold())
                            .foregroundStyle(Color.csTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        StatusBadge(
                            status: badgeStatus(for: report.estado)
                        )

                        Text(verbatim: metadata(for: report))
                            .font(.footnote)
                            .foregroundStyle(Color.csTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(
                            verbatim: report.anonimo
                                ? "Anónimo"
                                : report.autor?.nombre ?? "Usuario"
                        )
                        .font(.subheadline)
                        .foregroundStyle(Color.csTextSecondary)

                        if report.esMio {
                            Text(verbatim: "Tu reporte")
                                .font(.footnote.bold())
                                .foregroundStyle(Color.csNavy)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.withinCard)
                }
                .listRowBackground(Color.csSurface)

                if let review = report.revision {
                    Section {
                        ReportReviewCard(review: review)
                            .listRowInsets(EdgeInsets())
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    Text(verbatim: report.descripcion)
                        .font(.body)
                        .foregroundStyle(Color.csTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text(verbatim: "Descripción")
                }
                .listRowBackground(Color.csSurface)

                Section {
                    ReportedLinkCard(rawURL: report.urlPublicacion)
                        .listRowInsets(EdgeInsets())
                } header: {
                    Text(verbatim: "Enlace de la publicación")
                }
                .listRowBackground(Color.clear)

                ReportEvidenceSection(
                    evidences: report.evidencias
                )

                if let likeModel {
                    Section {
                        ReportLikeView(model: likeModel)
                    }
                    .listRowBackground(Color.csSurface)
                }

                commentsSection
            }

            if let message = model.errorMessage {
                ErrorBanner(message: message) {
                    retryReportRequested = true
                }
                .disabled(
                    model.isLoading
                        || retryReportRequested
                        || composerModel.isSending
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Detalle del reporte"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let report = model.report,
               report.esMio,
               report.estado == .pending {
                ToolbarItem(placement: .topBarTrailing) {
                    DeleteReportButton(
                        report: report,
                        api: api,
                        onEdited: {
                            await model.refresh()

                            guard !Task.isCancelled else {
                                return
                            }

                            synchronizeLikeModel()
                        }
                    )
                    .disabled(
                        composerModel.isSending
                            || likeModel?.isUpdating == true
                            || model.isLoading
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.report != nil {
                CommentComposerView(
                    model: composerModel,
                    onPublished: { _ in
                        await commentsModel.refresh()
                    }
                )
            }
        }
        .task {
            await model.loadInitial()

            guard !Task.isCancelled, model.report != nil else {
                return
            }

            synchronizeLikeModel()
            await commentsModel.loadInitial()
        }
        .refreshable {
            guard likeModel?.isUpdating != true,
                  !composerModel.isSending else {
                return
            }

            await model.refresh()

            guard !Task.isCancelled, model.report != nil else {
                return
            }

            synchronizeLikeModel()
            await commentsModel.refresh()
        }
        .task(id: retryReportRequested) {
            guard retryReportRequested else {
                return
            }

            guard likeModel?.isUpdating != true,
                  !composerModel.isSending else {
                retryReportRequested = false
                return
            }

            await model.refresh()

            guard !Task.isCancelled else {
                return
            }

            if model.report != nil {
                synchronizeLikeModel()
                await commentsModel.loadInitial()
            }

            guard !Task.isCancelled else {
                return
            }

            retryReportRequested = false
        }
        .task(id: retryCommentsRequested) {
            guard retryCommentsRequested else {
                return
            }

            await commentsModel.retry()

            guard !Task.isCancelled else {
                return
            }

            retryCommentsRequested = false
        }
        .onDisappear {
            retryReportRequested = false
            retryCommentsRequested = false
        }
    }

    private var commentsSection: some View {
        Section {
            if !commentsModel.hasLoaded,
               commentsModel.errorMessage == nil {
                loadingRow("Cargando comentarios")
            }

            if commentsModel.hasLoaded,
               commentsModel.comments.isEmpty {
                EmptyStateView(
                    symbol: "bubble.left",
                    title: "Todavía no hay comentarios",
                    message: "Los comentarios de este reporte aparecerán aquí."
                )
            }

            ForEach(commentsModel.comments) { comment in
                ReportCommentRow(
                    comment: comment,
                    api: api,
                    onDeleted: {
                        await commentsModel.refresh()
                    }
                )
            }

            if let message = commentsModel.errorMessage {
                ErrorBanner(message: message) {
                    retryCommentsRequested = true
                }
                .disabled(
                    commentsModel.isLoading || retryCommentsRequested
                )
            }

            if commentsModel.hasLoaded,
               commentsModel.hasMore,
               commentsModel.errorMessage == nil {
                loadingRow("Cargando más comentarios")
                    .task(id: commentsModel.comments.count) {
                        await commentsModel.loadMore()
                    }
            } else if commentsModel.hasLoaded,
                      commentsModel.isLoading {
                loadingRow("Actualizando comentarios")
            }
        } header: {
            Text(verbatim: "Comentarios")
        }
        .listRowBackground(Color.csSurface)
    }

    private func synchronizeLikeModel() {
        guard let report = model.report,
              model.errorMessage == nil,
              likeModel?.isUpdating != true else {
            return
        }

        likeModel = ReportLikeViewModel(report: report, api: api)
    }

    private func loadingRow(_ title: String) -> some View {
        HStack {
            Spacer()

            ProgressView()
                .accessibilityLabel(Text(verbatim: title))

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.withinCard)
    }

    private func badgeStatus(
        for status: ReportStatus
    ) -> StatusBadge.Status {
        switch status {
        case .pending:
            return .pending
        case .validated:
            return .validated
        case .rejected:
            return .rejected
        }
    }

    private func metadata(for report: Report) -> String {
        let platform = report.plataformaOtra
            ?? report.plataforma.nombre

        return "\(platform) • \(report.categoria.nombre) • "
            + formattedDate(report.fechaCreacion)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
