//
//  CaptchaChallenge.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct CaptchaChallenge: Decodable, Sendable {
    let algorithm: String
    let challenge: String
    let maxnumber: Int
    let salt: String
    let signature: String
}
