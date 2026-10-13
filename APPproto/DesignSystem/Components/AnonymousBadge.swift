//
//  AnonymousBadge.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

struct AnonymousBadge: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.withinCard / 2) {
            Image(systemName: "person.fill.questionmark")
                .accessibilityHidden(true)

            Text("Usuario anónimo")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.footnote)
        .foregroundStyle(Color.csTextSecondary)
        .padding(.horizontal, Theme.Spacing.withinCard)
        .padding(.vertical, Theme.Spacing.withinCard / 2)
        .background(Color.csSurface, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(
                    Color.csBorder,
                    lineWidth: Theme.BorderWidth.standard
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Usuario anónimo")
    }
}

private struct AnonymousBadgePreview: View {
    var body: some View {
        ScrollView {
            AnonymousBadge()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    AnonymousBadgePreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    AnonymousBadgePreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    AnonymousBadgePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
