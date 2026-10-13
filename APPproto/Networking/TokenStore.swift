//
//  TokenStore.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

actor TokenStore {
    typealias RefreshOperation =
        @Sendable (String) async throws -> Tokens

    private let keychain: KeychainTokenStore
    private var accessToken: String?
    private var refreshTask: Task<String, Error>?
    private var sessionID = UUID()

    init(keychain: KeychainTokenStore = KeychainTokenStore()) {
        self.keychain = keychain
    }

    func currentAccessToken() -> String? {
        accessToken
    }
    func hasRefreshToken() async throws -> Bool {
        try await keychain.loadRefreshToken() != nil
    }
    
    func store(_ tokens: Tokens) async throws {
        invalidateCurrentSession()
        let currentSessionID = sessionID

        do {
            try await persist(
                tokens,
                for: currentSessionID
            )
        } catch {
            if sessionID == currentSessionID {
                try await clear()
            }
            throw error
        }
    }

    func refreshAccessToken(
        rejectedAccessToken: String? = nil,
        using operation: @escaping RefreshOperation
    ) async throws -> String {
        if let refreshTask {
            return try await refreshTask.value
        }

        if
            let rejectedAccessToken,
            let accessToken,
            accessToken != rejectedAccessToken
        {
            return accessToken
        }

        let currentSessionID = sessionID

        let task = Task<String, Error> {
            do {
                guard
                    let refreshToken =
                        try await keychain.loadRefreshToken()
                else {
                    throw APIError.unauthorized
                }

                try Task.checkCancellation()

                let tokens = try await operation(refreshToken)

                try Task.checkCancellation()

                try await persist(
                    tokens,
                    for: currentSessionID
                )

                guard sessionID == currentSessionID else {
                    throw CancellationError()
                }

                refreshTask = nil
                return tokens.accessToken
            } catch {
                if sessionID == currentSessionID {
                    try await clear()
                }
                throw error
            }
        }

        refreshTask = task
        return try await task.value
    }

    func clear() async throws {
        invalidateCurrentSession()
        URLCache.shared.removeAllCachedResponses()
        try await keychain.deleteRefreshToken()
    }

    private func persist(
        _ tokens: Tokens,
        for expectedSessionID: UUID
    ) async throws {
        guard sessionID == expectedSessionID else {
            throw CancellationError()
        }

        guard
            !tokens.accessToken.isEmpty,
            !tokens.refreshToken.isEmpty,
            tokens.expiresIn > 0
        else {
            throw APIError.decoding
        }

        try await keychain.saveRefreshToken(tokens.refreshToken)

        guard sessionID == expectedSessionID else {
            throw CancellationError()
        }

        accessToken = tokens.accessToken
    }

    private func invalidateCurrentSession() {
        sessionID = UUID()
        refreshTask?.cancel()
        refreshTask = nil
        accessToken = nil
    }
}
