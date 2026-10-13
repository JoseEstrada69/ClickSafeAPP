//
//  VerifyEmailViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class VerifyEmailViewModel {
    nonisolated private struct VerifyBody: Encodable {
        let correo: String
        let codigo: String
    }

    nonisolated private struct ResendBody: Encodable {
        let correo: String
        let captcha: String
    }

    let email: String
    var code = ""

    private(set) var isLoading = false
    private(set) var resendSecondsRemaining = 60
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let api: any APIClient

    @ObservationIgnored
    private var resendDeadline: TimeInterval

    init(email: String, api: any APIClient) {
        self.email = email
        self.api = api
        resendDeadline = ProcessInfo.processInfo.systemUptime + 60
    }

    var canSubmit: Bool {
        !isLoading
            && code.count == 6
            && code.allSatisfy { "0123456789".contains($0) }
    }

    func verify() async -> Bool {
        guard canSubmit else { return false }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let body = try JSONEncoder().encode(
                VerifyBody(correo: email, codigo: code)
            )

            try await api.sendWithoutResponse(
                Endpoint(
                    path: "auth/verify-email",
                    method: .post,
                    body: body,
                    requiresAuthentication: false
                )
            )

            try Task.checkCancellation()

            code = ""
            return true
        } catch {
            handle(error)
            return false
        }
    }

    func resend() async {
        updateRemainingTime()

        guard !isLoading, resendSecondsRemaining == 0 else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            try await requestResend()

            try Task.checkCancellation()

            code = ""
            resendDeadline = ProcessInfo.processInfo.systemUptime + 60
            updateRemainingTime()
        } catch {
            handle(error)
        }
    }

    func runCountdown() async {
        while !Task.isCancelled {
            updateRemainingTime()

            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
        }
    }

    private func updateRemainingTime() {
        let remaining = resendDeadline
            - ProcessInfo.processInfo.systemUptime

        resendSecondsRemaining = max(0, Int(ceil(remaining)))
    }

    private func requestResend() async throws {
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
                    ResendBody(correo: email, captcha: captcha)
                )

                try await api.sendWithoutResponse(
                    Endpoint(
                        path: "auth/resend-verification",
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
