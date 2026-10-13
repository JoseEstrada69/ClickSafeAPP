//
//  MyReportScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

nonisolated enum MyReportsRoute: Hashable {
    case reportDetail(Int)
}

@MainActor
struct MyReportsScreen: View {
    @State private var model: MyReportsViewModel
    @State private var retryRequested = false

    init(api: any APIClient) {
        _model = State(
            initialValue: MyReportsViewModel(api: api)
        )
    }

    var body: some View {
        List {
            if !model.hasLoaded, model.errorMessage == nil {
                loadingRow("Cargando tus reportes")
            }

            if model.hasLoaded, model.reports.isEmpty {
                EmptyStateView(
                    symbol: "doc.text",
                    title: "Todavía no tienes reportes",
                    message: "Los reportes que publiques aparecerán aquí."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(model.reports) { report in
                NavigationLink(
                    value: MyReportsRoute.reportDetail(report.id)
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.Spacing.withinCard
                    ) {
                        ReportRow(
                            title: report.titulo,
                            platform: report.plataformaOtra
                                ?? report.plataforma.nombre,
                            category: report.categoria.nombre,
                            date: report.fechaCreacion,
                            status: badgeStatus(for: report.estado),
                            likeCount: report.totalLikes
                        )

                        if report.anonimo {
                            Text(verbatim: "Anónimo")
                                .font(.footnote)
                                .foregroundStyle(Color.csTextSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityHint(
                    Text(verbatim: "Ver el detalle del reporte")
                )
            }

            if let message = model.errorMessage {
                ErrorBanner(message: message) {
                    retryRequested = true
                }
                .disabled(model.isLoading || retryRequested)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if model.hasLoaded,
               model.hasMore,
               model.errorMessage == nil {
                loadingRow("Cargando más reportes")
                    .task(id: model.reports.count) {
                        await model.loadMore()
                    }
            } else if model.hasLoaded, model.isLoading {
                loadingRow("Actualizando tus reportes")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Mis reportes"))
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

    private func loadingRow(_ title: String) -> some View {
        HStack {
            Spacer()

            ProgressView()
                .accessibilityLabel(Text(verbatim: title))

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.withinCard)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
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
