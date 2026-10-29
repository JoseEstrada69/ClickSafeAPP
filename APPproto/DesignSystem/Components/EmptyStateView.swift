//
//  EmptyStateView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.Spacing.betweenBlocks) {
            Image(systemName: symbol)
                .font(.largeTitle)
                .foregroundStyle(Color.csTextSecondary)
                .accessibilityHidden(true)

            Text(verbatim: title)
                .font(.headline)
                .foregroundStyle(Color.csTextPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(verbatim: message)
                .font(.body)
                .foregroundStyle(Color.csTextSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.cardPadding)
    }
}

private struct EmptyStateViewPreview: View {
    var body: some View {
        ScrollView {
            EmptyStateView(
                symbol: "magnifyingglass",
                title: "No encontramos reportes",
                message: "Prueba con otra búsqueda."
            )
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    EmptyStateViewPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    EmptyStateViewPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    EmptyStateViewPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
