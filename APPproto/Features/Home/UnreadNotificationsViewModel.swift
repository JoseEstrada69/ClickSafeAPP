//
//  UnreadNotificationsViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 09/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class UnreadNotificationsViewModel {
    private nonisolated struct CountResponse: Decodable, Sendable {
        let count: Int
    }

    private(set) var count = 0
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func loadInitial() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading, !Task.isCancelled else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let response: CountResponse = try await api.send(
                Endpoint(path: "notifications/unread-count"),
                expecting: CountResponse.self
            )

            try Task.checkCancellation()

            guard response.count >= 0 else {
                throw APIError.decoding
            }

            count = response.count
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudo actualizar el contador de notificaciones."
        }

        switch apiError {
        case .offline:
            return "No hay conexión para actualizar las notificaciones."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudo actualizar el contador de notificaciones."
        }
    }
}
