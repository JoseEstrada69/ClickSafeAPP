//
//  MockAuthAPIClient.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import CryptoKit

actor MockAuthAPIClient: APIClient {
    private struct Account {
        var nombre: String
        var password: String
        var verified: Bool
    }

    private let contentAPI: MockAPIClient
    private var accounts: [String: Account] = [:]
    private var challenges: [String: String] = [:]
    private var refreshTokens: [String: String] = [:]
    private var currentEmail: String?
    private var currentRefreshToken: String?

    init() async {
        contentAPI = await MockAPIClient()

        accounts["demo@clicksafe.mx"] = Account(
            nombre: "Usuario de prueba",
            password: "Demo12345",
            verified: true
        )
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        expecting responseType: Response.Type
    ) async throws -> Response {
        let path = normalizedPath(endpoint)

        if endpoint.method == .get, path == "auth/captcha" {
            try await delay()
            return try decode(makeChallenge(), as: responseType)
        }

        if path == "me",
           endpoint.method == .get || endpoint.method == .patch {
            try await delay()

            guard let correo = currentEmail,
                  var account = accounts[correo] else {
                throw APIError.unauthorized
            }

            if endpoint.method == .patch {
                let body = try requestBody(endpoint)
                let nombre = try string("nombre", in: body)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard (1...100).contains(nombre.count) else {
                    throw APIError.validation(code: "INVALID_INPUT")
                }

                account.nombre = nombre
                accounts[correo] = account
            }

            return try decode(
                [
                    "nombre": account.nombre,
                    "correo": correo,
                    "rol": "usuario",
                    "fechaRegistro": "2026-10-07T12:00:00.000Z",
                    "totpActivo": false
                ],
                as: responseType
            )
        }

        if endpoint.method == .post, path.hasPrefix("auth/") {
            try await delay()
            let response = try handleAuth(endpoint, path: path)
            return try decode(response, as: responseType)
        }

        return try await contentAPI.send(
            endpoint,
            expecting: responseType
        )
    }

    func sendWithoutResponse(
        _ endpoint: Endpoint
    ) async throws {
        let path = normalizedPath(endpoint)

        if endpoint.method == .patch, path == "me/password" {
            try await delay()
            try changePassword(endpoint)
            return
        }

        if endpoint.method == .post, path.hasPrefix("auth/") {
            try await delay()
            _ = try handleAuth(endpoint, path: path)
            return
        }

        try await contentAPI.sendWithoutResponse(endpoint)
    }

    private func changePassword(
        _ endpoint: Endpoint
    ) throws {
        guard let correo = currentEmail,
              var account = accounts[correo] else {
            throw APIError.unauthorized
        }

        let body = try requestBody(endpoint)
        let currentPassword = try string("passwordActual", in: body)
        let newPassword = try string("nuevaPassword", in: body)

        guard account.password == currentPassword else {
            throw APIError.validation(code: "INVALID_CURRENT_PASSWORD")
        }

        guard (8...128).contains(newPassword.count) else {
            throw APIError.validation(code: "PASSWORD_WEAK")
        }

        account.password = newPassword
        accounts[correo] = account

        refreshTokens = refreshTokens.filter {
            $0.value != correo || $0.key == currentRefreshToken
        }
    }

    private func handleAuth(
        _ endpoint: Endpoint,
        path: String
    ) throws -> [String: Any] {
        if path == "auth/logout" || path == "auth/logout-all" {
            if path == "auth/logout-all",
               let correo = currentEmail {
                refreshTokens = refreshTokens.filter {
                    $0.value != correo
                }
            } else if let token = currentRefreshToken {
                refreshTokens.removeValue(forKey: token)
            }

            currentEmail = nil
            currentRefreshToken = nil
            return [:]
        }

        let body = try requestBody(endpoint)

        if path == "auth/refresh" {
            let token = try string("refreshToken", in: body)

            guard let correo = refreshTokens.removeValue(forKey: token),
                  accounts[correo]?.verified == true else {
                throw APIError.unauthorized
            }

            return issueTokens(for: correo)
        }

        let correo = try string("correo", in: body)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch path {
        case "auth/register":
            try validateCaptcha(body)

            let nombre = try string("nombre", in: body)
            let password = try string("password", in: body)

            guard (1...100).contains(nombre.count),
                  (8...128).contains(password.count) else {
                throw APIError.validation(code: "INVALID_INPUT")
            }

            if accounts[correo] == nil {
                accounts[correo] = Account(
                    nombre: nombre,
                    password: password,
                    verified: false
                )
            }

            return ["message": "Solicitud recibida."]

        case "auth/verify-email":
            let codigo = try string("codigo", in: body)

            guard codigo == "123456",
                  var account = accounts[correo] else {
                throw APIError.validation(code: "INVALID_CODE")
            }

            account.verified = true
            accounts[correo] = account

            return ["message": "Cuenta verificada."]

        case "auth/resend-verification", "auth/forgot-password":
            try validateCaptcha(body)
            return ["message": "Solicitud recibida."]

        case "auth/login":
            try validateCaptcha(body)

            let password = try string("password", in: body)

            guard let account = accounts[correo],
                  account.password == password else {
                throw APIError.unauthorized
            }

            guard account.verified else {
                throw APIError.validation(code: "EMAIL_NOT_VERIFIED")
            }

            return issueTokens(for: correo)

        case "auth/reset-password":
            try validateCaptcha(body)

            let codigo = try string("codigo", in: body)
            let password = try string("nuevaPassword", in: body)

            guard codigo == "12345678",
                  var account = accounts[correo] else {
                throw APIError.validation(code: "INVALID_CODE")
            }

            guard (8...128).contains(password.count) else {
                throw APIError.validation(code: "PASSWORD_WEAK")
            }

            account.password = password
            accounts[correo] = account

            refreshTokens = refreshTokens.filter {
                $0.value != correo
            }

            if currentEmail == correo {
                currentEmail = nil
                currentRefreshToken = nil
            }

            return ["message": "Contraseña actualizada."]

        default:
            throw APIError.notFound
        }
    }

    private func makeChallenge() -> [String: Any] {
        let salt = UUID().uuidString
        let signature = UUID().uuidString
        let challenge = hash(salt + "25")

        challenges[signature] = salt

        return [
            "algorithm": "SHA-256",
            "challenge": challenge,
            "maxnumber": 100,
            "salt": salt,
            "signature": signature
        ]
    }

    private func validateCaptcha(
        _ body: [String: Any]
    ) throws {
        guard let encoded = body["captcha"] as? String,
              let data = Data(base64Encoded: encoded),
              let payload = try? JSONSerialization.jsonObject(
                  with: data
              ) as? [String: Any],
              let signature = payload["signature"] as? String,
              let salt = challenges.removeValue(forKey: signature),
              payload["algorithm"] as? String == "SHA-256",
              payload["salt"] as? String == salt,
              let number = payload["number"] as? Int,
              (0...100).contains(number),
              payload["challenge"] as? String == hash(salt + "25"),
              hash(salt + String(number)) == hash(salt + "25") else {
            throw APIError.validation(code: "CAPTCHA_INVALID")
        }
    }

    private func issueTokens(
        for correo: String
    ) -> [String: Any] {
        let refreshToken = "mock-refresh-\(UUID().uuidString)"

        refreshTokens[refreshToken] = correo
        currentEmail = correo
        currentRefreshToken = refreshToken

        return [
            "accessToken": "mock-access-\(UUID().uuidString)",
            "refreshToken": refreshToken,
            "expiresIn": 900
        ]
    }

    private func requestBody(
        _ endpoint: Endpoint
    ) throws -> [String: Any] {
        guard let data = endpoint.body,
              let body = try? JSONSerialization.jsonObject(
                  with: data
              ) as? [String: Any] else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        return body
    }

    private func string(
        _ key: String,
        in body: [String: Any]
    ) throws -> String {
        guard let value = body[key] as? String,
              !value.isEmpty else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        return value
    }

    private func decode<Response: Decodable & Sendable>(
        _ object: [String: Any],
        as responseType: Response.Type
    ) throws -> Response {
        do {
            let data = try JSONSerialization.data(
                withJSONObject: object
            )

            return try APIDecoder.make().decode(
                responseType,
                from: data
            )
        } catch {
            throw APIError.decoding
        }
    }

    private func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map {
            String(format: "%02x", Int($0))
        }.joined()
    }

    private func normalizedPath(
        _ endpoint: Endpoint
    ) -> String {
        endpoint.path
            .split(separator: "/")
            .joined(separator: "/")
    }

    private func delay() async throws {
        try await Task.sleep(for: .milliseconds(500))
        try Task.checkCancellation()
    }
}
