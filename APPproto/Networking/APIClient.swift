//
//  APIClient.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

protocol APIClient: Sendable {
    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        expecting responseType: Response.Type
    ) async throws -> Response

    func sendWithoutResponse(
        _ endpoint: Endpoint
    ) async throws
}
