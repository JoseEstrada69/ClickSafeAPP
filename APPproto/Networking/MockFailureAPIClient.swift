//
//  MockFailureAPIClient.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 10/10/26.
//

import Foundation

#if DEBUG
actor MockFailureAPIClient: APIClient {
    private let base: MockAuthAPIClient
    private var remainingFailures: Int

    init(base: MockAuthAPIClient) {
        self.base = base

        remainingFailures = ProcessInfo.processInfo.arguments.contains(
            "-MockFailRecentReportsOnce"
        ) ? 1 : 0
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        expecting responseType: Response.Type
    ) async throws -> Response {
        try Task.checkCancellation()

        if remainingFailures > 0,
           isInitialRecentReportsRequest(endpoint) {
            remainingFailures -= 1

            try await Task.sleep(for: .milliseconds(500))
            try Task.checkCancellation()

            throw APIError.offline
        }

        return try await base.send(
            endpoint,
            expecting: responseType
        )
    }

    func sendWithoutResponse(
        _ endpoint: Endpoint
    ) async throws {
        try Task.checkCancellation()
        try await base.sendWithoutResponse(endpoint)
    }

    private func isInitialRecentReportsRequest(
        _ endpoint: Endpoint
    ) -> Bool {
        let path = endpoint.path
            .split(separator: "/")
            .joined(separator: "/")

        let order = endpoint.queryItems.first {
            $0.name == "orden"
        }?.value

        let page = endpoint.queryItems.first {
            $0.name == "page"
        }?.value

        return endpoint.method == .get
            && path == "reports"
            && order == "recientes"
            && page == "1"
    }
}
#endif
