//
//  KeychainTokenStoreTests.swift
//  APPprotoTests.
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import Testing
@testable import APPproto

@MainActor
struct KeychainTokenStoreTests {
    @Test("Guarda, actualiza, recupera y borra el refresh token")
    func refreshTokenLifecycle() async throws {
        let account = "test-\(UUID().uuidString)"
        let store = KeychainTokenStore(account: account)

        do {
            let initialToken = try await store.loadRefreshToken()
            #expect(initialToken == nil)

            try await store.saveRefreshToken("primer-token-de-prueba")

            let firstToken = try await store.loadRefreshToken()
            #expect(firstToken == "primer-token-de-prueba")

            try await store.saveRefreshToken("segundo-token-de-prueba")

            let updatedToken = try await store.loadRefreshToken()
            #expect(updatedToken == "segundo-token-de-prueba")

            let anotherStore = KeychainTokenStore(account: account)
            let persistedToken = try await anotherStore.loadRefreshToken()
            #expect(persistedToken == "segundo-token-de-prueba")

            try await store.deleteRefreshToken()

            let deletedToken = try await store.loadRefreshToken()
            #expect(deletedToken == nil)

            try await store.deleteRefreshToken()
        } catch {
            try await store.deleteRefreshToken()
            throw error
        }
    }

    @Test("Rechaza un token vacío y conserva el token anterior")
    func rejectsEmptyToken() async throws {
        let account = "test-\(UUID().uuidString)"
        let store = KeychainTokenStore(account: account)

        do {
            try await store.saveRefreshToken("token-valido-de-prueba")

            do {
                try await store.saveRefreshToken("")
                Issue.record("Se aceptó un token vacío.")
            } catch let error as KeychainTokenStore.StoreError {
                switch error {
                case .invalidToken:
                    break
                default:
                    Issue.record("Se recibió un error distinto al esperado.")
                }
            }

            let storedToken = try await store.loadRefreshToken()
            #expect(storedToken == "token-valido-de-prueba")

            try await store.deleteRefreshToken()
        } catch {
            try await store.deleteRefreshToken()
            throw error
        }
    }
}
