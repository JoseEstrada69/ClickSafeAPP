//
//  EvidenceURLValidator.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation

nonisolated enum EvidenceURLValidator {
    static func resolve(
        path: String?,
        baseURL: URL?
    ) -> URL? {
        guard
            let path,
            !path.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty,
            let baseURL,
            let baseHost = baseURL.host?.lowercased(),
            !baseHost.isEmpty,
            let baseScheme = baseURL.scheme?.lowercased(),
            baseURL.user == nil,
            baseURL.password == nil,
            let url = URL(
                string: path,
                relativeTo: baseURL
            )?.absoluteURL,
            url.host?.lowercased() == baseHost,
            url.scheme?.lowercased() == baseScheme,
            effectivePort(for: url) == effectivePort(for: baseURL),
            url.user == nil,
            url.password == nil
        else {
            return nil
        }

        #if DEBUG
        let isLocalHTTP = baseScheme == "http"
            && baseHost == "localhost"

        guard baseScheme == "https" || isLocalHTTP else {
            return nil
        }
        #else
        guard baseScheme == "https" else {
            return nil
        }
        #endif

        return url
    }

    private static func effectivePort(for url: URL) -> Int? {
        if let port = url.port {
            return port
        }

        switch url.scheme?.lowercased() {
        case "https":
            return 443
        case "http":
            return 80
        default:
            return nil
        }
    }
}
