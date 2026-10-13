//
//  ReportSearchQuery.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation

nonisolated struct ReportSearchQuery: Hashable, Sendable {
    enum StatusFilter: String, CaseIterable, Identifiable, Sendable {
        case all = ""
        case pending = "pendiente"
        case validated = "validado"
        case rejected = "rechazado"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return "Todos"
            case .pending:
                return "Pendientes"
            case .validated:
                return "Validados"
            case .rejected:
                return "No validados"
            }
        }
    }

    enum SortOrder: String, CaseIterable, Identifiable, Sendable {
        case recent = "recientes"
        case popular = "populares"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .recent:
                return "Recientes"
            case .popular:
                return "Populares"
            }
        }
    }

    var text = ""
    var platformID: Int?
    var categoryID: Int?
    var status: StatusFilter = .all
    var order: SortOrder = .recent

    var isValid: Bool {
        text.count <= 100
            && (platformID.map { $0 > 0 } ?? true)
            && (categoryID.map { $0 > 0 } ?? true)
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        let search = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !search.isEmpty {
            items.append(
                URLQueryItem(name: "q", value: search)
            )
        }

        if let platformID {
            items.append(
                URLQueryItem(
                    name: "plataforma",
                    value: String(platformID)
                )
            )
        }

        if let categoryID {
            items.append(
                URLQueryItem(
                    name: "categoria",
                    value: String(categoryID)
                )
            )
        }

        if status != .all {
            items.append(
                URLQueryItem(
                    name: "estado",
                    value: status.rawValue
                )
            )
        }

        items.append(
            URLQueryItem(
                name: "orden",
                value: order.rawValue
            )
        )

        return items
    }
}
