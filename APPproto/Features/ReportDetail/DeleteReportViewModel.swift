//
//  DeleteReportViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class DeleteReportViewModel {
    private(set) var isDeleting = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func delete(_ report: Report) async -> Bool {
        guard report.esMio,
              report.estado == .pending,
              !isDeleting,
              !Task.isCancelled else {
            return false
        }

        isDeleting = true
        errorMessage = nil

        defer {
            isDeleting = false
        }

        do {
            try await api.sendWithoutResponse(
                Endpoint(
                    path: "reports/\(report.id)",
                    method: .delete
                )
            )

            try Task.checkCancellation()
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = message(for: error)
            return false
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudo borrar el reporte. Intenta de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para borrar este reporte."

        case .conflict:
            return "El reporte cambió de estado y ya no se puede borrar."

        case .notFound:
            return "Este reporte ya no está disponible."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudo borrar el reporte. Intenta de nuevo."
        }
    }
}
