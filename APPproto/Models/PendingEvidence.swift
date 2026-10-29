//
//  PendingEvidence.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation

nonisolated struct PendingEvidence: Identifiable, Sendable {
    let id: UUID
    let jpegData: Data

    init(jpegData: Data) {
        id = UUID()
        self.jpegData = jpegData
    }
}
