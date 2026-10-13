//
//  EndpointTests.swift
//  APPprotoTests.
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import Testing
@testable import APPproto

@MainActor
struct EndpointTests {
    @Test("Conserva la ruta base y los parámetros de búsqueda")
    func buildsSearchRequest() throws {
        let baseURL = try #require(
            URL(string: "https://example.com/api/v1/")
        )

        let endpoint = Endpoint(
            path: "/reports",
            queryItems: [
                URLQueryItem(name: "q", value: "fraude & teléfono"),
                URLQueryItem(name: "page", value: "2")
            ]
        )

        let request = try endpoint.makeRequest(
            baseURL: baseURL,
            accessToken: "token-de-prueba"
        )

        let url = try #require(request.url)
        let components = try #require(
            URLComponents(url: url, resolvingAgainstBaseURL: false)
        )

        #expect(components.host == "example.com")
        #expect(components.path == "/api/v1/reports")
        #expect(components.queryItems == endpoint.queryItems)
        #expect(request.httpMethod == "GET")
        #expect(request.timeoutInterval == 20)
        #expect(
            request.cachePolicy == .reloadIgnoringLocalCacheData
        )
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == "Bearer token-de-prueba"
        )
    }

    @Test("Una petición pública no incluye el access token")
    func omitsAuthenticationForPublicRequest() throws {
        let baseURL = try #require(
            URL(string: "https://example.com/api/v1")
        )

        let endpoint = Endpoint(
            path: "auth/captcha",
            requiresAuthentication: false
        )

        let request = try endpoint.makeRequest(
            baseURL: baseURL,
            accessToken: "token-de-prueba"
        )

        #expect(
            request.value(forHTTPHeaderField: "Authorization") == nil
        )
        #expect(request.httpBody == nil)
        #expect(
            request.value(forHTTPHeaderField: "Content-Type") == nil
        )
        #expect(
            request.value(forHTTPHeaderField: "Accept")
                == "application/json"
        )
    }

    @Test("Incluye el cuerpo JSON y su tipo de contenido")
    func buildsJSONRequest() throws {
        let baseURL = try #require(
            URL(string: "https://example.com/api/v1")
        )

        let body = Data(#"{"nombre":"Nombre de prueba"}"#.utf8)
        let endpoint = Endpoint(
            path: "me",
            method: .patch,
            body: body
        )

        let request = try endpoint.makeRequest(
            baseURL: baseURL,
            accessToken: "token-de-prueba"
        )

        #expect(request.httpMethod == "PATCH")
        #expect(request.httpBody == body)
        #expect(
            request.value(forHTTPHeaderField: "Content-Type")
                == "application/json"
        )
    }

    @Test("Una petición autenticada requiere un token")
    func rejectsMissingAccessToken() throws {
        let baseURL = try #require(
            URL(string: "https://example.com/api/v1")
        )

        let endpoint = Endpoint(path: "me")

        do {
            _ = try endpoint.makeRequest(baseURL: baseURL)
            Issue.record("Se aceptó una petición sin token.")
        } catch let error as APIError {
            guard case .unauthorized = error else {
                Issue.record("Se recibió un error distinto al esperado.")
                throw error
            }
        }
    }

    @Test("Rechaza una ruta que intenta salir de la API")
    func rejectsInvalidPath() throws {
        let baseURL = try #require(
            URL(string: "https://example.com/api/v1")
        )

        let endpoint = Endpoint(
            path: "../reports",
            requiresAuthentication: false
        )

        do {
            _ = try endpoint.makeRequest(baseURL: baseURL)
            Issue.record("Se aceptó una ruta inválida.")
        } catch let error as APIError {
            guard case .validation(let code) = error else {
                Issue.record("Se recibió un error distinto al esperado.")
                throw error
            }

            #expect(code == "INVALID_ENDPOINT")
        }
    }
}
