//
//  ReportLikeResponse.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import Foundation

nonisolated struct ReportLikeResponse: Decodable, Sendable {
    let totalLikes: Int
    let likedByMe: Bool
}
