//
//  Review.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//
import Foundation

nonisolated struct Review: Decodable, Sendable {
    let decision: ReportStatus
    let comentario: String?
    let fecha: Date
}
