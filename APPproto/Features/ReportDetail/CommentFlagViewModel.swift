//
//  CommentFlagViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class CommentFlagViewModel {
    var reason: CommentFlagReason = .spam
    var detail = ""

    private(set) var isSending = false
    private(set) var errorMessage: String?
    private(set) var resultMessage: String?

    @ObservationIgnored
    private let comment: Comment

    @ObservationIgnored
    private let api: any APIClient

    private struct RequestBody: Encodable {
        let motivo: CommentFlagReason
        let detalle: String?
    }

    var canSubmit: Bool {
        !comment.esMio
            && !isSending
            && resultMessage == nil
            && detail.count <= 255
    }

    init(comment: Comment, api: any APIClient) {
        self.comment = comment
        self.api = api
    }

    func submit() async {
        guard canSubmit, !Task.isCancelled else {
            return
        }

        isSending = true
        errorMessage = nil

        defer {
            isSending = false
        }

        let trimmedDetail = detail.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        do {
            let body = try JSONEncoder().encode(
                RequestBody(
                    motivo: reason,
                    detalle: trimmedDetail.isEmpty
                        ? nil
                        : trimmedDetail
                )
            )

            try await api.sendWithoutResponse(
                Endpoint(
                    path: "comments/\(comment.id)/flags",
                    method: .post,
                    body: body
                )
            )

            try Task.checkCancellation()
            resultMessage = "Denuncia enviada."
        } catch is CancellationError {
            return
        } catch {
            if let apiError = error as? APIError,
               case .validation(let code) = apiError,
               code == "ALREADY_FLAGGED" {
                resultMessage = "Ya denunciaste este comentario."
            } else {
                errorMessage = message(for: error)
            }
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudo enviar la denuncia. Intenta de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para denunciar este comentario."

        case .notFound:
            return "Este comentario ya no está disponible."

        case .validation:
            return "Revisa el motivo y el detalle de la denuncia."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudo enviar la denuncia. Intenta de nuevo."
        }
    }
}
