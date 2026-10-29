//
//  CommentFlagReason.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation

nonisolated enum CommentFlagReason:
    String,
    CaseIterable,
    Identifiable,
    Encodable,
    Sendable
{
    case spam = "spam"
    case harassment = "acoso"
    case offensiveLanguage = "lenguaje_ofensivo"
    case personalInformation = "informacion_personal"
    case other = "otro"

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .spam:
            return "Spam"

        case .harassment:
            return "Acoso"

        case .offensiveLanguage:
            return "Lenguaje ofensivo"

        case .personalInformation:
            return "Información personal"

        case .other:
            return "Otro"
        }
    }
}
