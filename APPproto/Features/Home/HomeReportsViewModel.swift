//
//  HomeReportsViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeReportsViewModel {
    private(set) var reports: [Report] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var hasMore = false
    private(set) var errorMessage: String?

    private(set) var categories: [Category] = []
    private(set) var featuredReports: [Report] = []
    private(set) var isLoadingOverview = false
    private(set) var hasLoadedOverview = false
    private(set) var overviewErrorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private var nextPage = 1

    @ObservationIgnored
    private let pageSize = 20

    @ObservationIgnored
    private var failedRequestWasReset = true

    init(api: any APIClient) {
        self.api = api
    }

    func loadInitial() async {
        guard !hasLoaded else { return }
        await loadPage(reset: true)
    }

    func refresh() async {
        await loadPage(reset: true)
    }

    func loadMore() async {
        guard hasLoaded, hasMore, errorMessage == nil else {
            return
        }

        await loadPage(reset: false)
    }

    func retry() async {
        await loadPage(reset: failedRequestWasReset)
    }

    func loadOverview() async {
        guard !hasLoadedOverview else { return }
        await refreshOverview()
    }

    func refreshOverview() async {
        guard !isLoadingOverview, !Task.isCancelled else {
            return
        }

        isLoadingOverview = true
        overviewErrorMessage = nil

        defer {
            isLoadingOverview = false
        }

        do {
            async let categoriesRequest: [Category] = api.send(
                Endpoint(path: "categories"),
                expecting: [Category].self
            )

            async let featuredRequest: Page<Report> = api.send(
                Endpoint(
                    path: "reports",
                    queryItems: [
                        URLQueryItem(
                            name: "orden",
                            value: "populares"
                        ),
                        URLQueryItem(name: "page", value: "1"),
                        URLQueryItem(name: "limit", value: "5")
                    ]
                ),
                expecting: Page<Report>.self
            )

            let (loadedCategories, featuredPage) = try await (
                categoriesRequest,
                featuredRequest
            )

            try Task.checkCancellation()

            guard featuredPage.page == 1,
                  featuredPage.limit == 5,
                  featuredPage.total >= 0,
                  featuredPage.items.count <= 5 else {
                throw APIError.decoding
            }

            var categoryIDs = Set<Int>()
            var reportIDs = Set<Int>()

            categories = loadedCategories.filter {
                categoryIDs.insert($0.id).inserted
            }

            featuredReports = featuredPage.items.filter {
                reportIDs.insert($0.id).inserted
            }

            hasLoadedOverview = true
        } catch is CancellationError {
            return
        } catch {
            overviewErrorMessage = message(
                for: error,
                fallback: "No se pudieron cargar las categorías y los reportes destacados. Intenta de nuevo."
            )
        }
    }

    private func loadPage(reset: Bool) async {
        guard !isLoading, !Task.isCancelled else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        let requestedPage = reset ? 1 : nextPage

        do {
            let response: Page<Report> = try await api.send(
                Endpoint(
                    path: "reports",
                    queryItems: [
                        URLQueryItem(
                            name: "orden",
                            value: "recientes"
                        ),
                        URLQueryItem(
                            name: "page",
                            value: String(requestedPage)
                        ),
                        URLQueryItem(
                            name: "limit",
                            value: String(pageSize)
                        )
                    ]
                ),
                expecting: Page<Report>.self
            )

            try Task.checkCancellation()

            let followingPage = requestedPage
                .addingReportingOverflow(1)
            let consumedItems = requestedPage
                .multipliedReportingOverflow(by: pageSize)

            guard response.page == requestedPage,
                  response.limit == pageSize,
                  response.total >= 0,
                  response.items.count <= pageSize,
                  !followingPage.overflow,
                  !consumedItems.overflow else {
                throw APIError.decoding
            }

            if reset {
                var seenIDs = Set<Int>()

                reports = response.items.filter {
                    seenIDs.insert($0.id).inserted
                }
            } else {
                var seenIDs = Set(reports.map(\.id))

                reports.append(
                    contentsOf: response.items.filter {
                        seenIDs.insert($0.id).inserted
                    }
                )
            }

            nextPage = followingPage.partialValue
            hasMore = !response.items.isEmpty
                && consumedItems.partialValue < response.total
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            failedRequestWasReset = reset
            errorMessage = message(
                for: error,
                fallback: "No se pudieron cargar los reportes. Intenta de nuevo."
            )
        }
    }

    private func message(
        for error: Error,
        fallback: String
    ) -> String {
        guard let apiError = error as? APIError else {
            return fallback
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return fallback
        }
    }
}
