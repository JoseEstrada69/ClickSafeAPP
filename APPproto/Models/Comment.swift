//
//  Comment.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Comment: Decodable, Identifiable, Sendable {
    let id: Int
    let contenido: String
    let anonimo: Bool
    let autor: Author?
    let esMio: Bool
    let fechaCreacion: Date
}
