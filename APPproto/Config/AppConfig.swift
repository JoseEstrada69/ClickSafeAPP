//
//  AppConfig.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 05/10/26.
//
import Foundation

struct AppConfig {
    let apiBaseURL: URL?
    let useMockAPI: Bool

    init(bundle: Bundle = .main) throws {
        guard let mockValue = bundle.object(
            forInfoDictionaryKey: "UseMockAPI"
        ) as? String else {
            throw ConfigurationError.invalidMockSetting
        }

        switch mockValue.uppercased() {
        case "YES":
            useMockAPI = true
        case "NO":
            useMockAPI = false
        default:
            throw ConfigurationError.invalidMockSetting
        }

        #if !DEBUG
        guard !useMockAPI else {
            throw ConfigurationError.mockAPIInRelease
        }
        #endif

        let rawURL = (
            bundle.object(forInfoDictionaryKey: "APIBaseURL") as? String
            ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        if rawURL.isEmpty {
            guard useMockAPI else {
                throw ConfigurationError.invalidBaseURL
            }

            apiBaseURL = nil
            return
        }

        guard let url = URL(string: rawURL),
              let scheme = url.scheme?.lowercased(),
              let host = url.host,
              !host.isEmpty,
              url.user == nil,
              url.password == nil,
              url.query == nil,
              url.fragment == nil,
              url.path == "/api/v1" else {
            throw ConfigurationError.invalidBaseURL
        }

        #if DEBUG
        let isLocalHTTP = scheme == "http"
            && host.lowercased() == "localhost"

        guard scheme == "https" || isLocalHTTP else {
            throw ConfigurationError.insecureBaseURL
        }
        #else
        guard scheme == "https" else {
            throw ConfigurationError.insecureBaseURL
        }
        #endif

        apiBaseURL = url
    }
}

enum ConfigurationError: LocalizedError {
    case invalidMockSetting
    case invalidBaseURL
    case insecureBaseURL
    case mockAPIInRelease

    var errorDescription: String? {
        switch self {
        case .invalidMockSetting:
            return "UseMockAPI debe contener YES o NO."

        case .invalidBaseURL:
            return "Configura una URL válida que termine en /api/v1."

        case .insecureBaseURL:
            return "La conexión requiere HTTPS; HTTP solo se permite en localhost durante desarrollo."

        case .mockAPIInRelease:
            return "La versión de producción debe usar la API real."
        }
    }
}
