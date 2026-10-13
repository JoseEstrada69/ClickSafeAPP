//
//  Platform.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Platform: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let nombre: String
    let esOtra: Bool

    init(id: Int, nombre: String, esOtra: Bool = false) {
        self.id = id
        self.nombre = nombre
        self.esOtra = esOtra
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case nombre
        case esOtra
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        nombre = try container.decode(String.self, forKey: .nombre)
        esOtra = try container.decodeIfPresent(
            Bool.self,
            forKey: .esOtra
        ) ?? false
    }
}
