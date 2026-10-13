//
//  ReportSearchViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReportSearchViewModel {
    var query = ReportSearchQuery()

    private(set) var platforms: [Platform] = []
    private(set) var categories: [Category] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    var canSearch: Bool {
        hasLoaded
            && !isLoading
            && query.isValid
            && (
                query.platformID == nil
                    || platforms.contains {
                        $0.id == query.platformID
                    }
            )
            && (
                query.categoryID == nil
                    || categories.contains {
                        $0.id == query.categoryID
                    }
            )
    }

    var platformName: String {
        guard let id = query.platformID else {
            return "Todas"
        }

        return platforms.first {
            $0.id == id
        }?.nombre ?? "Seleccionar"
    }

    var categoryName: String {
        guard let id = query.categoryID else {
            return "Todas"
        }

        return categories.first {
            $0.id == id
        }?.nombre ?? "Seleccionar"
    }

    init(api: any APIClient) {
        self.api = api
    }

    func loadCatalogs() async {
        guard !isLoading,
              !hasLoaded,
              !Task.isCancelled else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            async let loadedPlatforms: [Platform] = api.send(
                Endpoint(path: "platforms"),
                expecting: [Platform].self
            )

            async let loadedCategories: [Category] = api.send(
                Endpoint(path: "categories"),
                expecting: [Category].self
            )

            let (platforms, categories) = try await (
                loadedPlatforms,
                loadedCategories
            )

            try Task.checkCancellation()

            self.platforms = platforms
            self.categories = categories
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No pudimos cargar los filtros. Inténtalo de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para consultar los filtros."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return "No pudimos cargar los filtros. Inténtalo de nuevo."
        }
    }
}
