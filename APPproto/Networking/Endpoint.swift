//
//  Endpoint.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let body: Data?
    let contentType: String
    let requiresAuthentication: Bool

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        contentType: String = "application/json",
        requiresAuthentication: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.contentType = contentType
        self.requiresAuthentication = requiresAuthentication
    }

    func makeRequest(
        baseURL: URL,
        accessToken: String? = nil
    ) throws -> URLRequest {
        guard
            var components = URLComponents(
                url: baseURL,
                resolvingAgainstBaseURL: false
            ),
            let scheme = components.scheme?.lowercased(),
            let host = components.host,
            !host.isEmpty,
            components.user == nil,
            components.password == nil,
            components.query == nil,
            components.fragment == nil
        else {
            throw APIError.validation(code: "INVALID_API_URL")
        }

        #if DEBUG
        guard scheme == "https" || scheme == "http" else {
            throw APIError.validation(code: "INVALID_API_URL")
        }
        #else
        guard scheme == "https" else {
            throw APIError.validation(code: "INVALID_API_URL")
        }
        #endif

        let allowedCharacters = CharacterSet(
            charactersIn:
                "abcdefghijklmnopqrstuvwxyz" +
                "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
                "0123456789/_-"
        )

        guard
            !path.isEmpty,
            path.unicodeScalars.allSatisfy({
                allowedCharacters.contains($0)
            })
        else {
            throw APIError.validation(code: "INVALID_ENDPOINT")
        }

        let segments = path.split(separator: "/")

        guard !segments.isEmpty else {
            throw APIError.validation(code: "INVALID_ENDPOINT")
        }

        let basePath = components.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpointPath = segments.joined(separator: "/")

        components.path = basePath.isEmpty
            ? "/\(endpointPath)"
            : "/\(basePath)/\(endpointPath)"

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.validation(code: "INVALID_API_URL")
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 20
        )

        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if body != nil {
            request.setValue(
                contentType,
                forHTTPHeaderField: "Content-Type"
            )
        }

        if requiresAuthentication {
            guard let accessToken, !accessToken.isEmpty else {
                throw APIError.unauthorized
            }

            request.setValue(
                "Bearer \(accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        return request
    }
}
