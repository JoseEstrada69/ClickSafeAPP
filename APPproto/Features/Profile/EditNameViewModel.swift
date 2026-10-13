//
//  EditNameViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class EditNameViewModel {
    nonisolated private struct UpdateNameBody: Encodable {
        let nombre: String
    }

    var name: String

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private let originalName: String

    init(name: String, api: any APIClient) {
        self.name = name
        originalName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        self.api = api
    }

    var canSubmit: Bool {
        !isLoading
            && (1...100).contains(normalizedName.count)
            && normalizedName != originalName
    }

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func save() async -> Me? {
        guard canSubmit else { return nil }

        let submittedName = normalizedName

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let body = try JSONEncoder().encode(
                UpdateNameBody(nombre: submittedName)
            )

            let user = try await api.send(
                Endpoint(
                    path: "me",
                    method: .patch,
                    body: body
                ),
                expecting: Me.self
            )

            try Task.checkCancellation()

            return user
        } catch {
            guard !(error is CancellationError),
                  !Task.isCancelled else {
                return nil
            }

            guard let apiError = error as? APIError else {
                errorMessage = "No se pudo completar la acción."
                return nil
            }

            switch apiError {
            case .validation:
                errorMessage =
                    "El nombre debe contener entre 1 y 100 caracteres."

            case .unauthorized:
                errorMessage = "Tu sesión expiró. Inicia sesión de nuevo."

            case .rateLimited:
                errorMessage =
                    "Demasiados intentos. Espera un momento e inténtalo de nuevo."

            case .offline:
                errorMessage = "Sin conexión. Revisa tu conexión a internet."

            case .server:
                errorMessage =
                    "Algo salió mal de nuestro lado. Inténtalo más tarde."

            default:
                errorMessage = "No se pudo completar la acción."
            }

            return nil
        }
    }
}
