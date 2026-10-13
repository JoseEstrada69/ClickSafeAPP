//
//  LoginViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    enum Outcome {
        case authenticated(Me)
        case verificationRequired(correo: String)
        case administratorAccount
    }

    nonisolated private struct LoginBody: Encodable {
        let correo: String
        let password: String
        let captcha: String
    }

    nonisolated private struct LoginResponse: Decodable, Sendable {
        let tokens: Tokens?
        let requiresAdministratorPanel: Bool

        private enum CodingKeys: String, CodingKey {
            case mfaRequired
            case mfaSetupRequired
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )

            let mfaRequired = try container.decodeIfPresent(
                Bool.self,
                forKey: .mfaRequired
            ) ?? false

            let mfaSetupRequired = try container.decodeIfPresent(
                Bool.self,
                forKey: .mfaSetupRequired
            ) ?? false

            requiresAdministratorPanel =
                mfaRequired || mfaSetupRequired

            if requiresAdministratorPanel {
                tokens = nil
            } else {
                tokens = try Tokens(from: decoder)
            }
        }
    }

    var email = ""
    var password = ""

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private let tokenStore: TokenStore

    init(
        api: any APIClient,
        tokenStore: TokenStore
    ) {
        self.api = api
        self.tokenStore = tokenStore
    }

    var canSubmit: Bool {
        !isLoading
            && !normalizedEmail.isEmpty
            && normalizedEmail.count <= 254
            && !password.isEmpty
    }

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func login() async -> Outcome? {
        guard canSubmit else { return nil }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        let correo = normalizedEmail
        var storedTokens = false

        do {
            let response = try await requestLogin(correo: correo)

            try Task.checkCancellation()

            if response.requiresAdministratorPanel {
                password = ""
                return .administratorAccount
            }

            guard let tokens = response.tokens else {
                throw APIError.decoding
            }

            try await tokenStore.store(tokens)
            storedTokens = true

            try Task.checkCancellation()

            let user = try await api.send(
                Endpoint(path: "me"),
                expecting: Me.self
            )

            try Task.checkCancellation()

            password = ""
            return .authenticated(user)
        } catch {
            if storedTokens {
                do {
                    try await tokenStore.clear()
                } catch {
                    errorMessage =
                        "No se pudo limpiar la sesión. Inténtalo de nuevo."
                    return nil
                }
            }

            guard !(error is CancellationError),
                  !Task.isCancelled else {
                return nil
            }

            if let apiError = error as? APIError {
                if case .validation(let code) = apiError,
                   code == "EMAIL_NOT_VERIFIED" {
                    password = ""
                    return .verificationRequired(correo: correo)
                }

                errorMessage = message(for: apiError)
            } else {
                errorMessage = "No se pudo completar la acción."
            }

            return nil
        }
    }

    private func requestLogin(
        correo: String
    ) async throws -> LoginResponse {
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
                    LoginBody(
                        correo: correo,
                        password: password,
                        captcha: captcha
                    )
                )

                return try await api.send(
                    Endpoint(
                        path: "auth/login",
                        method: .post,
                        body: body,
                        requiresAuthentication: false
                    ),
                    expecting: LoginResponse.self
                )
            } catch APIError.validation(let code)
                where code == "CAPTCHA_INVALID" && attempt == 0 {
                continue
            }
        }

        throw APIError.validation(code: "CAPTCHA_INVALID")
    }

    private func message(for error: APIError) -> String {
        switch error {
        case .unauthorized:
            return "Correo o contraseña incorrectos."

        case .rateLimited:
            return """
            Demasiados intentos. Espera un momento e inténtalo de nuevo.
            """

        case .validation(let code) where code == "CAPTCHA_INVALID":
            return """
            No pudimos verificar la solicitud. Inténtalo de nuevo.
            """

        case .offline:
            return "Sin conexión. Revisa tu conexión a internet."

        case .server:
            return "Algo salió mal de nuestro lado. Inténtalo más tarde."

        default:
            return "No se pudo completar la acción."
        }
    }
}
