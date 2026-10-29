//
//  Page.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

nonisolated struct Page<Item: Decodable & Sendable>: Decodable, Sendable {
    let items: [Item]
    let page: Int
    let limit: Int
    let total: Int
}
