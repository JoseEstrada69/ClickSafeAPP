//
//  ForgotPasswordViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ForgotPasswordViewModel {
    nonisolated private struct ForgotBody: Encodable {
        let correo: String
        let captcha: String
    }

    nonisolated private struct ResetBody: Encodable {
        let correo: String
        let codigo: String
        let nuevaPassword: String
        let captcha: String
    }

    var email = ""
    var code = ""
    var newPassword = ""
    var passwordConfirmation = ""

    private(set) var isResetStep = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private var recoveryEmail = ""

    init(api: any APIClient) {
        self.api = api
    }

    var canSubmit: Bool {
        guard !isLoading else { return false }

        if isResetStep {
            return code.count == 8
                && code.allSatisfy { "0123456789".contains($0) }
                && (8...128).contains(newPassword.count)
                && newPassword == passwordConfirmation
        }

        return isEmailValid
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

    func requestCode() async {
        guard !isResetStep, canSubmit else { return }

        let correo = normalizedEmail

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            try await sendWithCaptcha(path: "auth/forgot-password") {
                captcha in

                try JSONEncoder().encode(
                    ForgotBody(
                        correo: correo,
                        captcha: captcha
                    )
                )
            }

            try Task.checkCancellation()

            recoveryEmail = correo
            isResetStep = true
        } catch {
            handle(error)
        }
    }

    func resetPassword() async -> String? {
        guard isResetStep, canSubmit else { return nil }

        let correo = recoveryEmail
        let codigo = code
        let password = newPassword

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            try await sendWithCaptcha(path: "auth/reset-password") {
                captcha in

                try JSONEncoder().encode(
                    ResetBody(
                        correo: correo,
                        codigo: codigo,
                        nuevaPassword: password,
                        captcha: captcha
                    )
                )
            }

            try Task.checkCancellation()

            code = ""
            newPassword = ""
            passwordConfirmation = ""

            return correo
        } catch {
            handle(error)
            return nil
        }
    }

    private func sendWithCaptcha(
        path: String,
        makeBody: (String) throws -> Data
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

                let body = try makeBody(captcha)

                try await api.sendWithoutResponse(
                    Endpoint(
                        path: path,
                        method: .post,
                        body: body,
                        requiresAuthentication: false
                    )
                )

                return
            } catch APIError.validation(let code)
                where code == "CAPTCHA_INVALID" && attempt == 0 {
                continue
            }
        }

        throw APIError.validation(code: "CAPTCHA_INVALID")
    }

    private func handle(_ error: Error) {
        guard !(error is CancellationError),
              !Task.isCancelled else {
            return
        }

        guard let apiError = error as? APIError else {
            errorMessage = "No se pudo completar la acción."
            return
        }

        switch apiError {
        case .validation(let code) where code == "INVALID_CODE":
            errorMessage = "Código incorrecto o expirado."

        case .validation(let code) where code == "PASSWORD_WEAK":
            errorMessage = "Elige una contraseña más segura."

        case .validation(let code) where code == "CAPTCHA_INVALID":
            errorMessage =
                "No pudimos verificar la solicitud. Inténtalo de nuevo."

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
    }
}
