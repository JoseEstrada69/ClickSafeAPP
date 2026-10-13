//
//  MyReportsViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class MyReportsViewModel {
    private(set) var reports: [Report] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var hasMore = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private var nextPage = 1

    @ObservationIgnored
    private let pageSize = 20

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
        await loadPage(reset: !hasLoaded)
    }

    private func loadPage(reset: Bool) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        let requestedPage = reset ? 1 : nextPage

        do {
            let response: Page<Report> = try await api.send(
                Endpoint(
                    path: "me/reports",
                    queryItems: [
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

            guard response.page == requestedPage,
                  response.limit > 0,
                  response.total >= 0 else {
                throw APIError.decoding
            }

            if reset {
                reports = response.items
            } else {
                let existingIDs = Set(reports.map(\.id))

                reports.append(
                    contentsOf: response.items.filter {
                        !existingIDs.contains($0.id)
                    }
                )
            }

            nextPage = response.page + 1
            hasMore = !response.items.isEmpty
                && reports.count < response.total
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudieron cargar tus reportes. Intenta de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .rateLimited:
            return "Demasiados intentos. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudieron cargar tus reportes. Intenta de nuevo."
        }
    }
}
