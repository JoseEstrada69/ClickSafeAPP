//
//  ReportSearchResultsViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReportSearchResultsViewModel {
    private(set) var reports: [Report] = []
    private(set) var total = 0
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var hasMore = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private let query: ReportSearchQuery

    @ObservationIgnored
    private let pageSize = 20

    @ObservationIgnored
    private var nextPage = 1

    @ObservationIgnored
    private var failedRequestWasReset = true

    init(
        query: ReportSearchQuery,
        api: any APIClient
    ) {
        self.query = query
        self.api = api
    }

    func loadInitial() async {
        guard !hasLoaded else {
            return
        }

        await load(reset: true)
    }

    func refresh() async {
        await load(reset: true)
    }

    func loadMore() async {
        guard hasLoaded,
              hasMore,
              errorMessage == nil else {
            return
        }

        await load(reset: false)
    }

    func retry() async {
        await load(reset: failedRequestWasReset)
    }

    private func load(reset: Bool) async {
        guard !isLoading, !Task.isCancelled else {
            return
        }

        guard query.isValid else {
            errorMessage =
                "La búsqueda admite un máximo de 100 caracteres."
            failedRequestWasReset = reset
            return
        }

        isLoading = true
        errorMessage = nil
        failedRequestWasReset = reset

        defer {
            isLoading = false
        }

        let requestedPage = reset ? 1 : nextPage

        var queryItems = query.queryItems
        queryItems.append(
            URLQueryItem(
                name: "page",
                value: String(requestedPage)
            )
        )
        queryItems.append(
            URLQueryItem(
                name: "limit",
                value: String(pageSize)
            )
        )

        do {
            let page: Page<Report> = try await api.send(
                Endpoint(
                    path: "reports",
                    queryItems: queryItems
                ),
                expecting: Page<Report>.self
            )

            try Task.checkCancellation()

            guard page.page == requestedPage,
                  page.limit == pageSize,
                  page.total >= 0,
                  page.items.count <= pageSize else {
                throw APIError.decoding
            }

            let offset = (requestedPage - 1)
                .multipliedReportingOverflow(by: pageSize)
            let followingPage = requestedPage
                .addingReportingOverflow(1)

            guard !offset.overflow,
                  !followingPage.overflow else {
                throw APIError.decoding
            }

            var updated = reset ? [] : reports
            var existingIDs = Set(updated.map(\.id))

            for report in page.items {
                if existingIDs.insert(report.id).inserted {
                    updated.append(report)
                }
            }

            reports = updated
            total = page.total
            nextPage = followingPage.partialValue
            hasLoaded = true

            let remaining = max(0, page.total - offset.partialValue)
            hasMore = !page.items.isEmpty
                && page.items.count < remaining
        } catch is CancellationError {
            return
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No pudimos cargar los resultados. Inténtalo de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para consultar estos reportes."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        case .validation:
            return "No se pudo realizar la búsqueda. Revisa los filtros."

        default:
            return "No pudimos cargar los resultados. Inténtalo de nuevo."
        }
    }
}
