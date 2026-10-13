//
//  MockAPIClientTests.swift
//  APPprotoTests.
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import Testing
@testable import APPproto

@MainActor
struct MockAPIClientTests {
    @Test("La paginación entrega 25 reportes sin repetirlos")
    func paginatesReports() async throws {
        let client = await MockAPIClient()

        let first = try await client.send(
            Endpoint(path: "reports"),
            expecting: Page<Report>.self
        )

        let second = try await client.send(
            Endpoint(
                path: "reports",
                queryItems: [
                    URLQueryItem(name: "page", value: "2")
                ]
            ),
            expecting: Page<Report>.self
        )

        #expect(first.page == 1)
        #expect(first.limit == 20)
        #expect(first.total == 25)
        #expect(first.items.count == 20)

        #expect(second.page == 2)
        #expect(second.total == 25)
        #expect(second.items.count == 5)

        let firstIDs = Set(first.items.map(\.id))
        let secondIDs = Set(second.items.map(\.id))

        #expect(firstIDs.isDisjoint(with: secondIDs))
        #expect(firstIDs.union(secondIDs).count == 25)
    }

    @Test("Los reportes anónimos no exponen el autor")
    func protectsAnonymousAuthors() async throws {
        let client = await MockAPIClient()

        let page = try await client.send(
            Endpoint(
                path: "reports",
                queryItems: [
                    URLQueryItem(name: "limit", value: "100")
                ]
            ),
            expecting: Page<Report>.self
        )

        let anonymous = page.items.filter(\.anonimo)
        let identified = page.items.filter { !$0.anonimo }

        #expect(!anonymous.isEmpty)
        #expect(!identified.isEmpty)
        #expect(anonymous.allSatisfy { $0.autor == nil })
        #expect(identified.allSatisfy { $0.autor != nil })
    }

    @Test("Combina filtros y entrega solamente reportes propios")
    func filtersReports() async throws {
        let client = await MockAPIClient()

        let page = try await client.send(
            Endpoint(
                path: "me/reports",
                queryItems: [
                    URLQueryItem(name: "estado", value: "pendiente"),
                    URLQueryItem(name: "plataforma", value: "1"),
                    URLQueryItem(name: "q", value: "fraude")
                ]
            ),
            expecting: Page<Report>.self
        )

        #expect(page.total == 1)

        let report = try #require(page.items.first)

        #expect(report.id == 25)
        #expect(report.esMio)
        #expect(report.estado.rawValue == "pendiente")
        #expect(report.plataforma.id == 1)
    }

    @Test("Marcar una notificación actualiza las no leídas")
    func marksNotificationAsRead() async throws {
        let client = await MockAPIClient()

        let unreadEndpoint = Endpoint(
            path: "notifications",
            queryItems: [
                URLQueryItem(name: "leida", value: "false")
            ]
        )

        let initial = try await client.send(
            unreadEndpoint,
            expecting: Page<AppNotification>.self
        )

        #expect(initial.total == 4)

        try await client.sendWithoutResponse(
            Endpoint(
                path: "notifications/1/read",
                method: .patch
            )
        )

        let updated = try await client.send(
            unreadEndpoint,
            expecting: Page<AppNotification>.self
        )

        #expect(updated.total == 3)
        #expect(!updated.items.contains { $0.id == 1 })

        try await client.sendWithoutResponse(
            Endpoint(
                path: "notifications/read-all",
                method: .patch
            )
        )

        let finalPage = try await client.send(
            unreadEndpoint,
            expecting: Page<AppNotification>.self
        )

        #expect(finalPage.total == 0)
        #expect(finalPage.items.isEmpty)
    }

    @Test("El error forzado se puede desactivar")
    func recoversFromForcedError() async throws {
        let client = await MockAPIClient(
            forcedError: .offline
        )

        do {
            _ = try await client.send(
                Endpoint(path: "platforms"),
                expecting: [Platform].self
            )

            Issue.record("La solicitud debía fallar sin conexión.")
        } catch let error as APIError {
            guard case .offline = error else {
                Issue.record("Se recibió un error distinto al esperado.")
                throw error
            }
        }

        await client.setForcedError(nil)

        let platforms = try await client.send(
            Endpoint(path: "platforms"),
            expecting: [Platform].self
        )

        #expect(platforms.count == 4)
        #expect(platforms.filter(\.esOtra).count == 1)
    }

    @Test("Rechaza una página inválida")
    func rejectsInvalidPagination() async throws {
        let client = await MockAPIClient()

        do {
            _ = try await client.send(
                Endpoint(
                    path: "reports",
                    queryItems: [
                        URLQueryItem(name: "page", value: "0")
                    ]
                ),
                expecting: Page<Report>.self
            )

            Issue.record("Se aceptó una página inválida.")
        } catch let error as APIError {
            guard case .validation(let code) = error else {
                Issue.record("Se recibió un error distinto al esperado.")
                throw error
            }

            #expect(code == "INVALID_PAGINATION")
        }
    }
}
