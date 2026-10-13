//
//  ReportEditDraft.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation

nonisolated struct ReportEditDraft: Sendable {
    var title: String
    var description: String
    var publicationURL: String
    var platformID: Int
    var otherPlatform: String
    var categoryID: Int
    var isAnonymous: Bool

    init(report: Report) {
        title = report.titulo
        description = report.descripcion
        publicationURL = report.urlPublicacion
        platformID = report.plataforma.id
        otherPlatform = report.plataformaOtra ?? ""
        categoryID = report.categoria.id
        isAnonymous = report.anonimo
    }
}
