//
//  ReportDetailViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReportDetailViewModel {
    private(set) var report: Report?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let reportID: Int

    @ObservationIgnored
    private let api: any APIClient

    init(reportID: Int, api: any APIClient) {
        self.reportID = reportID
        self.api = api
    }

    func loadInitial() async {
        guard report == nil else { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let response: Report = try await api.send(
                Endpoint(path: "reports/\(reportID)"),
                expecting: Report.self
            )

            try Task.checkCancellation()

            guard response.id == reportID else {
                throw APIError.decoding
            }

            report = response
        } catch is CancellationError {
            return
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudo cargar el reporte. Intenta de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .notFound:
            return "Este reporte ya no está disponible."

        case .forbidden:
            return "No tienes permiso para consultar este reporte."

        case .rateLimited:
            return "Demasiados intentos. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudo cargar el reporte. Intenta de nuevo."
        }
    }
}
