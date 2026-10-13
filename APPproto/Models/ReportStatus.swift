//
//  ReportStatus.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated enum ReportStatus: String, Decodable, Sendable {
    case pending = "pendiente"
    case validated = "validado"
    case rejected = "rechazado"
}
