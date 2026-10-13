//
//  Category.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Category: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let nombre: String
    let descripcion: String?
}
