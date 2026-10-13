//
//  ReportLikeVIewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReportLikeViewModel {
    private(set) var totalLikes: Int
    private(set) var likedByMe: Bool
    private(set) var isUpdating = false
    private(set) var errorMessage: String?

    let isOwnReport: Bool

    @ObservationIgnored
    private let reportID: Int

    @ObservationIgnored
    private let api: any APIClient

    init(report: Report, api: any APIClient) {
        reportID = report.id
        totalLikes = report.totalLikes
        likedByMe = report.likedByMe
        isOwnReport = report.esMio
        self.api = api
    }

    func toggleLike() async {
        guard !isOwnReport, !isUpdating else {
            return
        }

        guard !Task.isCancelled else {
            return
        }

        let previousCount = totalLikes
        let previousLiked = likedByMe

        isUpdating = true
        errorMessage = nil

        likedByMe.toggle()

        if likedByMe {
            totalLikes += 1
        } else {
            totalLikes = max(0, totalLikes - 1)
        }

        defer {
            isUpdating = false
        }

        do {
            let response: ReportLikeResponse = try await api.send(
                Endpoint(
                    path: "reports/\(reportID)/like",
                    method: likedByMe ? .post : .delete
                ),
                expecting: ReportLikeResponse.self
            )

            try Task.checkCancellation()

            guard response.totalLikes >= 0 else {
                throw APIError.decoding
            }

            totalLikes = response.totalLikes
            likedByMe = response.likedByMe
        } catch is CancellationError {
            totalLikes = previousCount
            likedByMe = previousLiked
        } catch {
            totalLikes = previousCount
            likedByMe = previousLiked
            errorMessage = message(for: error)
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudo actualizar tu reacción. Intenta de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para reaccionar a este reporte."

        case .notFound:
            return "Este reporte ya no está disponible."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudo actualizar tu reacción. Intenta de nuevo."
        }
    }
}
