//
//  Report.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Report: Decodable, Identifiable, Sendable {
    let id: Int
    let titulo: String
    let descripcion: String
    let urlPublicacion: String

    let plataforma: Platform
    let plataformaOtra: String?
    let categoria: Category

    let estado: ReportStatus
    let anonimo: Bool
    let autor: Author?

    let esMio: Bool
    let likedByMe: Bool
    let totalLikes: Int
    let totalComentarios: Int

    let evidencias: [Evidence]
    let revision: Review?

    let fechaCreacion: Date
    let fechaActualizacion: Date
}
