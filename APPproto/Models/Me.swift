//
//  Me.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Me: Decodable, Sendable {
    let nombre: String
    let correo: String
    let rol: String
    let fechaRegistro: Date
    let totpActivo: Bool
}
