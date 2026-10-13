//
//  HomeScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct HomeScreen: View {
    private let api: any APIClient
    private let onSearch: () -> Void

    @Environment(AppState.self) private var appState

    @State private var model: HomeReportsViewModel
    @State private var unreadModel: UnreadNotificationsViewModel
    @State private var showsNotifications = false
    @State private var retryRequested = false
    @State private var overviewRetryRequested = false

    init(
        api: any APIClient,
        onSearch: @escaping () -> Void
    ) {
        self.api = api
        self.onSearch = onSearch

        _model = State(
            initialValue: HomeReportsViewModel(api: api)
        )

        _unreadModel = State(
            initialValue: UnreadNotificationsViewModel(api: api)
        )
    }

    var body: some View {
        List {
            introductionSection
            categoriesSection
            featuredSection
            recentSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "ClickSafe"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            Color.csNavBar,
            for: .navigationBar
        )
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                notificationsButton
            }
        }
        .navigationDestination(
            isPresented: $showsNotifications
        ) {
            NotificationsScreen(
                api: api,
                unreadModel: unreadModel
            )
        }
        .navigationDestination(
            for: ReportSearchRoute.self
        ) { route in
            switch route {
            case .results(let query):
                ReportSearchResultsScreen(
                    query: query,
                    api: api
                )

            case .reportDetail(let reportID):
                ReportDetailScreen(
                    reportID: reportID,
                    api: api
                )
            }
        }
        .task {
            async let overview: Void = model.loadOverview()
            async let recent: Void = loadRecentReports()
            async let count: Void = unreadModel.refresh()
            _ = await (overview, recent, count)
        }
        .refreshable {
            async let overview: Void = model.refreshOverview()
            async let recent: Void = model.refresh()
            async let count: Void = unreadModel.refresh()
            _ = await (overview, recent, count)
        }
        .task(id: retryRequested) {
            guard retryRequested else { return }

            await model.retry()

            guard !Task.isCancelled else { return }
            retryRequested = false
        }
        .task(id: overviewRetryRequested) {
            guard overviewRetryRequested else { return }

            await model.refreshOverview()

            guard !Task.isCancelled else { return }
            overviewRetryRequested = false
        }
        .onDisappear {
            retryRequested = false
            overviewRetryRequested = false
        }
    }

    private var notificationsButton: some View {
        Button {
            showsNotifications = true
        } label: {
            Image(systemName: "bell")
                .font(.body)
                .foregroundStyle(Color.white)
                .overlay(alignment: .topTrailing) {
                    if unreadModel.count > 0 {
                        Circle()
                            .fill(Color.csGold)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                .frame(
                    minWidth: Theme.Size.minimumTouchTarget,
                    minHeight: Theme.Size.minimumTouchTarget
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "Notificaciones"))
        .accessibilityValue(
            Text(
                verbatim: unreadModel.hasLoaded
                    ? "\(unreadModel.count) sin leer"
                    : "Contador no disponible"
            )
        )
        .accessibilityHint(
            Text(verbatim: "Abrir la lista de notificaciones")
        )
    }

    private var introductionSection: some View {
        Section {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                if let user = appState.currentUser {
                    Text(verbatim: "Hola, \(user.nombre)")
                        .font(.title2.bold())
                        .foregroundStyle(Color.csTextPrimary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Button(action: onSearch) {
                    CSCard {
                        HStack(
                            spacing: Theme.Spacing.withinCard
                        ) {
                            Image(systemName: "magnifyingglass")
                                .accessibilityHidden(true)

                            Text(
                                verbatim:
                                    "Pega un enlace o busca reportes…"
                            )
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                            Spacer(minLength: 0)
                        }
                        .font(.body)
                        .foregroundStyle(Color.csTextSecondary)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: Theme.Size.minimumTouchTarget,
                            alignment: .leading
                        )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint(
                    Text(verbatim: "Abrir el campo de búsqueda")
                )

                actionCard(
                    title: "Consultar reportes",
                    message: "Busca antecedentes antes de comprar",
                    symbol: "magnifyingglass",
                    action: onSearch
                )

            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var categoriesSection: some View {
        Section {
            if !model.categories.isEmpty {
                ScrollView(.horizontal) {
                    HStack(
                        spacing: Theme.Spacing.withinCard
                    ) {
                        ForEach(model.categories, id: \.id) {
                            category in

                            NavigationLink(
                                value: ReportSearchRoute.results(
                                    query(for: category)
                                )
                            ) {
                                Text(verbatim: category.nombre)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.csNavy)
                                    .padding(
                                        .horizontal,
                                        Theme.Spacing.withinCard
                                    )
                                    .frame(
                                        minHeight:
                                            Theme.Size.minimumTouchTarget
                                    )
                                    .background(
                                        Color.csSurface,
                                        in: Capsule()
                                    )
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(
                                                Color.csBorder,
                                                lineWidth:
                                                    Theme.BorderWidth.standard
                                            )
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(
                                Text(
                                    verbatim:
                                        "Ver reportes de este tipo de fraude"
                                )
                            )
                        }
                    }
                    .padding(
                        .vertical,
                        Theme.BorderWidth.standard
                    )
                }
                .scrollIndicators(.hidden)
            } else if model.hasLoadedOverview {
                Text(verbatim: "No hay categorías disponibles.")
                    .font(.body)
                    .foregroundStyle(Color.csTextSecondary)
            } else if model.overviewErrorMessage == nil {
                loadingRow("Cargando tipos de fraude")
            }
        } header: {
            Text(verbatim: "Tipos de fraude")
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var featuredSection: some View {
        Section {
            if !model.hasLoadedOverview,
               model.overviewErrorMessage == nil {
                loadingRow("Cargando reportes destacados")
            }

            if model.hasLoadedOverview,
               model.featuredReports.isEmpty {
                EmptyStateView(
                    symbol: "star",
                    title: "Todavía no hay reportes destacados",
                    message: "Los reportes más populares aparecerán aquí."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(model.featuredReports) { report in
                reportLink(report)
            }

            if let message = model.overviewErrorMessage {
                ErrorBanner(message: message) {
                    overviewRetryRequested = true
                }
                .disabled(
                    model.isLoadingOverview
                        || overviewRetryRequested
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if model.hasLoadedOverview,
               model.isLoadingOverview {
                loadingRow("Actualizando reportes destacados")
            }
        } header: {
            Text(verbatim: "Reportes destacados")
        }
    }

    private var recentSection: some View {
        Section {
            if !model.hasLoaded,
               model.errorMessage == nil {
                loadingRow("Cargando reportes")
            }

            if model.hasLoaded, model.reports.isEmpty {
                EmptyStateView(
                    symbol: "doc.text",
                    title: "Todavía no hay reportes",
                    message: "Los reportes recientes aparecerán aquí."
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(model.reports) { report in
                reportLink(report)
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
                loadingRow("Actualizando reportes")
            }
        } header: {
            Text(verbatim: "Recientes")
        }
    }

    private func actionCard(
        title: String,
        message: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            CSCard {
                HStack(
                    alignment: .top,
                    spacing: Theme.Spacing.withinCard
                ) {
                    Image(systemName: symbol)
                        .font(.title2)
                        .foregroundStyle(Color.csNavy)
                        .accessibilityHidden(true)

                    VStack(
                        alignment: .leading,
                        spacing: Theme.Spacing.withinCard
                    ) {
                        Text(verbatim: title)
                            .font(.headline)
                            .foregroundStyle(Color.csTextPrimary)

                        Text(verbatim: message)
                            .font(.body)
                            .foregroundStyle(Color.csTextSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.csTextSecondary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: Theme.Size.minimumTouchTarget)
            }
        }
        .buttonStyle(.plain)
    }

    private func reportLink(_ report: Report) -> some View {
        NavigationLink(
            value: ReportSearchRoute.reportDetail(report.id)
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

    private func query(
        for category: Category
    ) -> ReportSearchQuery {
        var query = ReportSearchQuery()
        query.categoryID = category.id
        return query
    }

    private func loadRecentReports() async {
        if model.hasLoaded {
            await model.refresh()
        } else {
            await model.loadInitial()
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
