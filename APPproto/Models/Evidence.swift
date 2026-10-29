//
//  Evidence.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Evidence: Decodable, Identifiable, Sendable {
    let id: Int
    let url: String
}
