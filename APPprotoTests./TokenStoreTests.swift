//
//  TokenStoreTests.swift
//  APPprotoTests.
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import Testing
@testable import APPproto

@MainActor
struct TokenStoreTests {
    @Test("Guarda los tokens y elimina la sesión")
    func storesAndClearsSession() async throws {
        try await withTestStore { store, keychain in
            let tokens = Tokens(
                accessToken: "access-de-prueba",
                refreshToken: "refresh-de-prueba",
                expiresIn: 900
            )

            try await store.store(tokens)

            let accessToken = await store.currentAccessToken()
            let refreshToken = try await keychain.loadRefreshToken()

            #expect(accessToken == "access-de-prueba")
            #expect(refreshToken == "refresh-de-prueba")

            let anotherStore = TokenStore(keychain: keychain)
            let anotherAccessToken =
                await anotherStore.currentAccessToken()

            #expect(anotherAccessToken == nil)

            try await store.clear()

            let clearedAccessToken =
                await store.currentAccessToken()
            let clearedRefreshToken =
                try await keychain.loadRefreshToken()

            #expect(clearedAccessToken == nil)
            #expect(clearedRefreshToken == nil)
        }
    }

    @Test("Cinco solicitudes usan una sola renovación")
    func sharesRefreshOperation() async throws {
        try await withTestStore { store, keychain in
            try await store.store(
                Tokens(
                    accessToken: "access-anterior",
                    refreshToken: "refresh-anterior",
                    expiresIn: 900
                )
            )

            let counter = RefreshCounter()
            let renewedTokens = Tokens(
                accessToken: "access-renovado",
                refreshToken: "refresh-renovado",
                expiresIn: 900
            )

            let operation: TokenStore.RefreshOperation = { token in
                #expect(token == "refresh-anterior")
                await counter.increment()

                try await Task.sleep(for: .milliseconds(100))

                return renewedTokens
            }

            let results = try await withThrowingTaskGroup(
                of: String.self
            ) { group in
                for _ in 0..<5 {
                    group.addTask {
                        try await store.refreshAccessToken(
                            rejectedAccessToken: "access-anterior",
                            using: operation
                        )
                    }
                }

                var values: [String] = []

                for try await value in group {
                    values.append(value)
                }

                return values
            }

            let refreshCount = await counter.value()
            let accessToken = await store.currentAccessToken()
            let refreshToken = try await keychain.loadRefreshToken()

            #expect(results.count == 5)
            #expect(results.allSatisfy { $0 == "access-renovado" })
            #expect(refreshCount == 1)
            #expect(accessToken == "access-renovado")
            #expect(refreshToken == "refresh-renovado")
        }
    }

    @Test("Una renovación fallida elimina las credenciales")
    func clearsSessionAfterRefreshFailure() async throws {
        try await withTestStore { store, keychain in
            try await store.store(
                Tokens(
                    accessToken: "access-anterior",
                    refreshToken: "refresh-anterior",
                    expiresIn: 900
                )
            )

            do {
                _ = try await store.refreshAccessToken(
                    rejectedAccessToken: "access-anterior"
                ) { _ in
                    throw APIError.unauthorized
                }

                Issue.record("La renovación debía fallar.")
            } catch let error as APIError {
                switch error {
                case .unauthorized:
                    break
                default:
                    Issue.record("Se recibió un error distinto al esperado.")
                }
            }

            let accessToken = await store.currentAccessToken()
            let refreshToken = try await keychain.loadRefreshToken()

            #expect(accessToken == nil)
            #expect(refreshToken == nil)
        }
    }

    private func withTestStore(
        _ body: @MainActor (
            TokenStore,
            KeychainTokenStore
        ) async throws -> Void
    ) async throws {
        let keychain = KeychainTokenStore(
            account: "test-\(UUID().uuidString)"
        )
        let store = TokenStore(keychain: keychain)

        do {
            try await body(store, keychain)
            try await store.clear()
        } catch {
            try await store.clear()
            throw error
        }
    }
}

private actor RefreshCounter {
    private var count = 0

    func increment() {
        count += 1
    }

    func value() -> Int {
        count
    }
}
