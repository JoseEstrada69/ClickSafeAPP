//
//  ReportCreationDraft.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation

nonisolated struct ReportCreationDraft: Sendable {
    var publicationURL: String
    var title = ""
    var platformID: Int?
    var otherPlatform = ""
    var categoryID: Int?
    var description = ""
    var isAnonymous = false
    var evidences: [PendingEvidence] = []

    init(publicationURL: String = "") {
        self.publicationURL = publicationURL
    }
}
