//
//  ChangesPasswordViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ChangePasswordViewModel {
    private nonisolated struct ChangePasswordBody: Encodable {
        let passwordActual: String
        let nuevaPassword: String
    }

    var currentPassword = ""
    var newPassword = ""
    var confirmation = ""

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    var canSubmit: Bool {
        !isLoading
            && !currentPassword.isEmpty
            && (8...128).contains(newPassword.count)
            && newPassword == confirmation
    }

    func save() async -> Bool {
        guard canSubmit else { return false }

        let body = ChangePasswordBody(
            passwordActual: currentPassword,
            nuevaPassword: newPassword
        )

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let data = try JSONEncoder().encode(body)

            try await api.sendWithoutResponse(
                Endpoint(
                    path: "me/password",
                    method: .patch,
                    body: data
                )
            )

            currentPassword = ""
            newPassword = ""
            confirmation = ""

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
            return "No se pudo cambiar la contraseña. Intenta de nuevo."
        }

        switch apiError {
        case .validation:
            return "Revisa la contraseña actual y los datos ingresados."

        case .unauthorized:
            return "No se pudo autorizar el cambio. Revisa tu sesión."

        case .rateLimited:
            return "Demasiados intentos. Intenta más tarde."

        case .offline:
            return "No se pudo conectar. Revisa tu conexión e intenta de nuevo."

        default:
            return "No se pudo cambiar la contraseña. Intenta de nuevo."
        }
    }
}
