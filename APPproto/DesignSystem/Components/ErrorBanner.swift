//
//  ErrorBanner.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

struct ErrorBanner: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        CSCard {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.withinCard
            ) {
                HStack(
                    alignment: .top,
                    spacing: Theme.Spacing.withinCard
                ) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.csDanger)
                        .accessibilityHidden(true)

                    Text(verbatim: message)
                        .foregroundStyle(Color.csTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.body)

                SecondaryButton(
                    title: "Reintentar",
                    action: retryAction
                )
            }
        }
    }
}

private struct ErrorBannerPreview: View {
    @State private var retryCount = 0

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                ErrorBanner(
                    message: "No pudimos cargar los reportes. Inténtalo de nuevo."
                ) {
                    retryCount += 1
                }

                Text(verbatim: "Reintentos solicitados: \(retryCount)")
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    ErrorBannerPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    ErrorBannerPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    ErrorBannerPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
