//
//  DeleteCommentView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class DeleteCommentViewModel {
    private(set) var isDeleting = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func delete(_ comment: Comment) async -> Bool {
        guard comment.esMio,
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
                    path: "comments/\(comment.id)",
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

    func clearError() {
        errorMessage = nil
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudo borrar el comentario. Intenta de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para borrar este comentario."

        case .notFound:
            return "Este comentario ya no está disponible."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudo borrar el comentario. Intenta de nuevo."
        }
    }
}
