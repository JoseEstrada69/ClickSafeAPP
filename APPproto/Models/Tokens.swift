//
//  Tokens.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Tokens: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}
