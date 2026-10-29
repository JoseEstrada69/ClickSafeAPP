//
//  AppNotification.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct AppNotification: Decodable, Identifiable, Sendable {
    let id: Int
    let tipo: String
    let mensaje: String
    let leida: Bool
    let reporteId: Int
    let fechaCreacion: Date
}
