//
//  LiveAPIClient.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import OSLog

actor LiveAPIClient: APIClient {
    private struct RefreshBody: Encodable {
        let refreshToken: String
    }

    private struct ErrorResponse: Decodable {
        let code: String?
    }

    private let baseURL: URL
    private let tokenStore: TokenStore
    private let session: URLSession
    private let onSessionExpired: @Sendable () async -> Void

    private let logger = Logger(
        subsystem: "mx.clicksafe",
        category: "Networking"
    )

    init(
        baseURL: URL,
        tokenStore: TokenStore,
        onSessionExpired: @escaping @Sendable () async -> Void
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.onSessionExpired = onSessionExpired

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 20
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil

        self.session = URLSession(
            configuration: configuration,
            delegate: APIRedirectDelegate(),
            delegateQueue: nil
        )
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        expecting responseType: Response.Type
    ) async throws -> Response {
        let data = try await perform(endpoint)

        do {
            return try APIDecoder.make().decode(
                responseType,
                from: data
            )
        } catch {
            throw APIError.decoding
        }
    }

    func sendWithoutResponse(
        _ endpoint: Endpoint
    ) async throws {
        _ = try await perform(endpoint)
    }

    private func perform(
        _ endpoint: Endpoint
    ) async throws -> Data {
        try Task.checkCancellation()

        var accessToken: String?

        if endpoint.requiresAuthentication {
            accessToken = await tokenStore.currentAccessToken()

            if accessToken == nil {
                accessToken = try await refreshAccessToken(
                    rejectedAccessToken: nil
                )
            }
        }

        var result = try await execute(
            endpoint,
            accessToken: accessToken
        )

        if result.response.statusCode == 401,
           endpoint.requiresAuthentication {
            let renewedToken = try await refreshAccessToken(
                rejectedAccessToken: accessToken
            )

            try Task.checkCancellation()

            result = try await execute(
                endpoint,
                accessToken: renewedToken
            )

            if result.response.statusCode == 401 {
                let currentToken = await tokenStore.currentAccessToken()

                if currentToken == renewedToken {
                    try await tokenStore.clear()
                    await onSessionExpired()
                }

                throw APIError.unauthorized
            }
        }

        try validate(
            result.response,
            data: result.data
        )

        return result.data
    }

    private func refreshAccessToken(
        rejectedAccessToken: String?
    ) async throws -> String {
        do {
            return try await tokenStore.refreshAccessToken(
                rejectedAccessToken: rejectedAccessToken
            ) { [self] refreshToken in
                try await requestNewTokens(
                    refreshToken: refreshToken
                )
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            await onSessionExpired()
            throw APIError.unauthorized
        }
    }

    private func requestNewTokens(
        refreshToken: String
    ) async throws -> Tokens {
        let body = try JSONEncoder().encode(
            RefreshBody(refreshToken: refreshToken)
        )

        let endpoint = Endpoint(
            path: "auth/refresh",
            method: .post,
            body: body,
            requiresAuthentication: false
        )

        let result = try await execute(
            endpoint,
            accessToken: nil
        )

        try validate(
            result.response,
            data: result.data
        )

        do {
            return try APIDecoder.make().decode(
                Tokens.self,
                from: result.data
            )
        } catch {
            throw APIError.decoding
        }
    }

    private func execute(
        _ endpoint: Endpoint,
        accessToken: String?
    ) async throws -> (
        data: Data,
        response: HTTPURLResponse
    ) {
        try Task.checkCancellation()

        var request = try endpoint.makeRequest(
            baseURL: baseURL,
            accessToken: accessToken
        )

        let data: Data
        let response: URLResponse

        do {
            if endpoint.contentType.hasPrefix("multipart/form-data"),
               let body = endpoint.body {
                request.httpBody = nil

                (data, response) = try await session.upload(
                    for: request,
                    from: body
                )
            } else {
                (data, response) = try await session.data(
                    for: request
                )
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if error.code == .cancelled {
                throw CancellationError()
            }

            throw APIError.offline
        } catch {
            throw APIError.server
        }

        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.server
        }

        logger.debug(
            "Respuesta HTTP: \(httpResponse.statusCode, privacy: .public)"
        )

        return (data, httpResponse)
    }

    private func validate(
        _ response: HTTPURLResponse,
        data: Data
    ) throws {
        let statusCode = response.statusCode

        if (200...299).contains(statusCode) {
            return
        }

        switch statusCode {
        case 400, 422:
            let errorResponse = try? JSONDecoder().decode(
                ErrorResponse.self,
                from: data
            )

            throw APIError.validation(
                code: errorResponse?.code ?? "UNKNOWN"
            )

        case 401:
            throw APIError.unauthorized

        case 403:
            throw APIError.forbidden

        case 404:
            throw APIError.notFound

        case 409:
            throw APIError.conflict

        case 429:
            throw APIError.rateLimited

        default:
            throw APIError.server
        }
    }
}

private final class APIRedirectDelegate:
    NSObject,
    URLSessionTaskDelegate
{
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
