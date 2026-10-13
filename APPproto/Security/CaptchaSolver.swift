//
//  CaptchaSolver.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import CryptoKit

enum CaptchaSolver {
    nonisolated static func solve(
        _ challenge: CaptchaChallenge
    ) async throws -> String {
        try Task.checkCancellation()

        guard challenge.algorithm == "SHA-256",
              challenge.maxnumber >= 0 else {
            throw APIError.validation(code: "CAPTCHA_INVALID")
        }

        let worker = Task.detached(priority: .userInitiated) {
            let startedAt = ProcessInfo.processInfo.systemUptime

            for number in 0...challenge.maxnumber {
                if number.isMultiple(of: 1_000) {
                    try Task.checkCancellation()
                }

                let input = Data(
                    (challenge.salt + String(number)).utf8
                )

                let digest = SHA256.hash(data: input)
                let hexadecimal = digest.map {
                    String(format: "%02x", Int($0))
                }.joined()

                guard hexadecimal == challenge.challenge else {
                    continue
                }

                try Task.checkCancellation()

                let elapsed = ProcessInfo.processInfo.systemUptime
                    - startedAt

                let payload: [String: Any] = [
                    "algorithm": challenge.algorithm,
                    "challenge": challenge.challenge,
                    "number": number,
                    "salt": challenge.salt,
                    "signature": challenge.signature,
                    "took": Int(elapsed * 1_000)
                ]

                let data = try JSONSerialization.data(
                    withJSONObject: payload
                )

                return data.base64EncodedString()
            }

            try Task.checkCancellation()
            throw APIError.validation(code: "CAPTCHA_INVALID")
        }

        return try await withTaskCancellationHandler {
            let result = try await worker.value
            try Task.checkCancellation()
            return result
        } onCancel: {
            worker.cancel()
        }
    }
}
