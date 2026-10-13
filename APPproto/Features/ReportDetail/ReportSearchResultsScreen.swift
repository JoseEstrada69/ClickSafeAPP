//
//  ReportSearchResultsScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

nonisolated enum ReportSearchRoute: Hashable {
    case results(ReportSearchQuery)
    case reportDetail(Int)
}

@MainActor
struct ReportSearchResultsScreen: View {

    private let query: ReportSearchQuery

    @State private var model: ReportSearchResultsViewModel
    @State private var retryRequested = false

    init(
        query: ReportSearchQuery,
        api: any APIClient
    ) {
        self.query = query

        _model = State(
            initialValue: ReportSearchResultsViewModel(
                query: query,
                api: api
            )
        )
    }

    var body: some View {
        List {
            if model.hasLoaded {
                Section {
                    Text(
                        verbatim: "\(model.total) reportes encontrados"
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color.csTextSecondary)
                }
            }

            if model.isLoading, !model.hasLoaded {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Cargando resultados")
                }
            }

            if model.hasLoaded,
               model.reports.isEmpty,
               model.errorMessage == nil {
                Section {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "No encontramos reportes",
                        message:
                            "La ausencia de reportes no garantiza que una persona o publicación sea legítima."
                    )

                }
            }

            if !model.reports.isEmpty {
                Section {
                    ForEach(model.reports) { report in
                        NavigationLink(
                            value: ReportSearchRoute.reportDetail(
                                report.id
                            )
                        ) {
                            ReportRow(
                                title: report.titulo,
                                platform: platformName(for: report),
                                category: report.categoria.nombre,
                                date: report.fechaCreacion,
                                status: badgeStatus(for: report.estado),
                                likeCount: report.totalLikes
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(
                            "Ver el detalle del reporte"
                        )
                        .task {
                            if report.id == model.reports.last?.id {
                                await model.loadMore()
                            }
                        }
                    }
                }
            }

            if let message = model.errorMessage {
                Section {
                    ErrorBanner(message: message) {
                        retryRequested = true
                    }
                    .disabled(
                        model.isLoading || retryRequested
                    )
                }
            }

            if model.isLoading, model.hasLoaded {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Cargando reportes")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.csBackground)
        .navigationTitle(Text(verbatim: "Resultados"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model.hasLoaded {
                await model.refresh()
            } else {
                await model.loadInitial()
            }
        }
        .refreshable {
            await model.refresh()
        }
        .task(id: retryRequested) {
            guard retryRequested else {
                return
            }

            await model.retry()

            guard !Task.isCancelled else {
                return
            }

            retryRequested = false
        }
        .onDisappear {
            retryRequested = false
        }
    }

    private func platformName(for report: Report) -> String {
        if report.plataforma.esOtra {
            return report.plataformaOtra
                ?? report.plataforma.nombre
        }

        return report.plataforma.nombre
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
}
