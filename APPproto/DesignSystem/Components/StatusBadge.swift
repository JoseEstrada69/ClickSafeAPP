//
//  StatusBadge.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

struct StatusBadge: View {
    enum Status: CaseIterable {
        case pending
        case validated
        case rejected
    }

    let status: Status

    private var appearance: (
        title: String,
        symbol: String,
        foreground: Color,
        background: Color
    ) {
        switch status {
        case .pending:
            return (
                "Pendiente de revisión",
                "clock",
                .csPendingFg,
                .csPendingBg
            )

        case .validated:
            return (
                "Fraude validado",
                "exclamationmark.shield.fill",
                .csValidatedFg,
                .csValidatedBg
            )

        case .rejected:
            return (
                "No validado",
                "xmark.shield",
                .csRejectedFg,
                .csRejectedBg
            )
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.withinCard / 2) {
            Image(systemName: appearance.symbol)
                .accessibilityHidden(true)

            Text(verbatim: appearance.title)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.footnote)
        .foregroundStyle(appearance.foreground)
        .padding(.horizontal, Theme.Spacing.withinCard)
        .padding(.vertical, Theme.Spacing.withinCard / 2)
        .background(appearance.background, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: appearance.title))
    }
}

private struct StatusBadgePreview: View {
    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                ForEach(StatusBadge.Status.allCases, id: \.self) {
                    status in

                    StatusBadge(status: status)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    StatusBadgePreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    StatusBadgePreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    StatusBadgePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
