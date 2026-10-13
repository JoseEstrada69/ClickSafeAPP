//
//  RegisterViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    nonisolated private struct RegisterBody: Encodable {
        let nombre: String
        let correo: String
        let password: String
        let captcha: String
    }

    nonisolated private struct RegisterResponse: Decodable, Sendable {
        let message: String
    }

    var name = ""
    var email = ""
    var password = ""
    var passwordConfirmation = ""

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    var canSubmit: Bool {
        !isLoading
            && (1...100).contains(normalizedName.count)
            && isEmailValid
            && (8...128).contains(password.count)
            && password == passwordConfirmation
    }

    private var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEmailValid: Bool {
        let correo = normalizedEmail

        guard correo.count <= 254,
              !correo.contains(where: { $0.isWhitespace }) else {
            return false
        }

        let parts = correo.split(
            separator: "@",
            omittingEmptySubsequences: false
        )

        return parts.count == 2
            && !parts[0].isEmpty
            && !parts[1].isEmpty
    }

    func register() async -> String? {
        guard canSubmit else { return nil }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        let nombre = normalizedName
        let correo = normalizedEmail
        let submittedPassword = password

        do {
            try await submitRegistration(
                nombre: nombre,
                correo: correo,
                password: submittedPassword
            )

            try Task.checkCancellation()

            password = ""
            passwordConfirmation = ""

            return correo
        } catch {
            guard !(error is CancellationError),
                  !Task.isCancelled else {
                return nil
            }

            if let apiError = error as? APIError {
                errorMessage = message(for: apiError)
            } else {
                errorMessage = "No se pudo completar la acción."
            }

            return nil
        }
    }

    private func submitRegistration(
        nombre: String,
        correo: String,
        password: String
    ) async throws {
        for attempt in 0..<2 {
            do {
                let challenge = try await api.send(
                    Endpoint(
                        path: "auth/captcha",
                        requiresAuthentication: false
                    ),
                    expecting: CaptchaChallenge.self
                )

                let captcha = try await CaptchaSolver.solve(challenge)

                try Task.checkCancellation()

                let body = try JSONEncoder().encode(
                    RegisterBody(
                        nombre: nombre,
                        correo: correo,
                        password: password,
                        captcha: captcha
                    )
                )

                _ = try await api.send(
                    Endpoint(
                        path: "auth/register",
                        method: .post,
                        body: body,
                        requiresAuthentication: false
                    ),
                    expecting: RegisterResponse.self
                )

                return
            } catch APIError.validation(let code)
                where code == "CAPTCHA_INVALID" && attempt == 0 {
                continue
            }
        }

        throw APIError.validation(code: "CAPTCHA_INVALID")
    }

    private func message(for error: APIError) -> String {
        switch error {
        case .validation(let code) where code == "PASSWORD_WEAK":
            return "Elige una contraseña más segura."

        case .validation(let code) where code == "CAPTCHA_INVALID":
            return "No pudimos verificar la solicitud. Inténtalo de nuevo."

        case .rateLimited:
            return "Demasiados intentos. Espera un momento e inténtalo de nuevo."

        case .offline:
            return "Sin conexión. Revisa tu conexión a internet."

        case .server:
            return "Algo salió mal de nuestro lado. Inténtalo más tarde."

        default:
            return "No se pudo completar la acción."
        }
    }
}
