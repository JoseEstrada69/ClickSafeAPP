//
//  APPprotoTests_.swift
//  APPprotoTests.
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import Testing
@testable import APPproto

@MainActor
struct CaptchaSolverTests {
    private let expectedHash =
        "bdefcbb18f485340bba7f76be066d180a7d4b1a4f1c47ca4f745da60e2024671"

    @Test("Resuelve el CAPTCHA e incluye los datos requeridos")
    func solvesChallenge() async throws {
        let challenge = CaptchaChallenge(
            algorithm: "SHA-256",
            challenge: expectedHash,
            maxnumber: 42,
            salt: "clicksafe-test-",
            signature: "test-signature"
        )

        let solution = try await CaptchaSolver.solve(challenge)
        let data = try #require(Data(base64Encoded: solution))
        let object = try JSONSerialization.jsonObject(with: data)
        let payload = try #require(object as? [String: Any])

        #expect(payload["algorithm"] as? String == "SHA-256")
        #expect(payload["challenge"] as? String == expectedHash)
        #expect(payload["number"] as? Int == 42)
        #expect(payload["salt"] as? String == "clicksafe-test-")
        #expect(payload["signature"] as? String == "test-signature")

        let elapsed = try #require(payload["took"] as? Int)
        #expect(elapsed >= 0)

        let expectedKeys: Set<String> = [
            "algorithm",
            "challenge",
            "number",
            "salt",
            "signature",
            "took"
        ]
        #expect(Set(payload.keys) == expectedKeys)
    }

    @Test("Rechaza un CAPTCHA sin solución dentro del límite")
    func rejectsUnsolvableChallenge() async throws {
        let challenge = CaptchaChallenge(
            algorithm: "SHA-256",
            challenge: expectedHash,
            maxnumber: 41,
            salt: "clicksafe-test-",
            signature: "test-signature"
        )

        try await expectInvalidChallenge(challenge)
    }

    @Test("Rechaza un algoritmo no admitido")
    func rejectsUnsupportedAlgorithm() async throws {
        let challenge = CaptchaChallenge(
            algorithm: "SHA-512",
            challenge: expectedHash,
            maxnumber: 42,
            salt: "clicksafe-test-",
            signature: "test-signature"
        )

        try await expectInvalidChallenge(challenge)
    }

    @Test("Rechaza un límite negativo")
    func rejectsNegativeLimit() async throws {
        let challenge = CaptchaChallenge(
            algorithm: "SHA-256",
            challenge: expectedHash,
            maxnumber: -1,
            salt: "clicksafe-test-",
            signature: "test-signature"
        )

        try await expectInvalidChallenge(challenge)
    }

    private func expectInvalidChallenge(
        _ challenge: CaptchaChallenge
    ) async throws {
        do {
            _ = try await CaptchaSolver.solve(challenge)
            Issue.record("El CAPTCHA inválido fue aceptado.")
        } catch let error as APIError {
            switch error {
            case .validation(let code):
                #expect(code == "CAPTCHA_INVALID")
            default:
                Issue.record("Se recibió un error distinto al esperado.")
            }
        }
    }
}
