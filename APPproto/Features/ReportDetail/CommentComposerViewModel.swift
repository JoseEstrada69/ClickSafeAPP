//
//  CommentComposerViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class CommentComposerViewModel {
    var content = ""
    var isAnonymous = false

    private(set) var isSending = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let reportID: Int

    @ObservationIgnored
    private let api: any APIClient

    private struct RequestBody: Encodable {
        let contenido: String
        let anonimo: Bool
    }

    var characterCount: Int {
        content.count
    }

    var canSubmit: Bool {
        let trimmed = content.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return !isSending
            && !trimmed.isEmpty
            && characterCount <= 1000
    }

    init(reportID: Int, api: any APIClient) {
        self.reportID = reportID
        self.api = api
    }

    func submit() async -> Comment? {
        guard canSubmit, !Task.isCancelled else {
            return nil
        }

        isSending = true
        errorMessage = nil

        defer {
            isSending = false
        }

        let submittedContent = content
        let submittedAnonymous = isAnonymous

        do {
            let body = try JSONEncoder().encode(
                RequestBody(
                    contenido: submittedContent.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                    anonimo: submittedAnonymous
                )
            )

            let comment: Comment = try await api.send(
                Endpoint(
                    path: "reports/\(reportID)/comments",
                    method: .post,
                    body: body
                ),
                expecting: Comment.self
            )

            try Task.checkCancellation()

            if content == submittedContent,
               isAnonymous == submittedAnonymous {
                content = ""
                isAnonymous = false
            }

            return comment
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = message(for: error)
            return nil
        }
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudo enviar el comentario. Intenta de nuevo."
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para comentar en este reporte."

        case .notFound:
            return "Este reporte ya no está disponible."

        case .validation:
            return "Revisa tu comentario. Debe contener entre 1 y 1000 caracteres."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudo enviar el comentario. Intenta de nuevo."
        }
    }
}
