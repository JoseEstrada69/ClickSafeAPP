//
//  ReportLinkSafariView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI
import SafariServices

@MainActor
struct ReportedLinkSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(
        context: Context
    ) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(
        _ controller: SFSafariViewController,
        context: Context
    ) {}
}
