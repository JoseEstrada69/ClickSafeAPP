//
//  CSCard.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

struct CSCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.cardPadding)
            .background(
                Color.csSurface,
                in: RoundedRectangle(
                    cornerRadius: Theme.CornerRadius.card
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: Theme.CornerRadius.card
                )
                .strokeBorder(
                    Color.csBorder,
                    lineWidth: Theme.BorderWidth.standard
                )
            }
    }
}

private struct CSCardPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                CSCard {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.Spacing.withinCard
                    ) {
                        Text("Reporte de ejemplo")
                            .font(.headline)
                            .foregroundStyle(Color.csTextPrimary)

                        Text("Esta tarjeta agrupa la información de un reporte.")
                            .font(.body)
                            .foregroundStyle(Color.csTextPrimary)

                        Text("Información de prueba")
                            .font(.footnote)
                            .foregroundStyle(Color.csTextSecondary)
                    }
                }

                CSCard {
                    Text("La tarjeta también admite contenido breve.")
                        .font(.body)
                        .foregroundStyle(Color.csTextPrimary)
                }
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    CSCardPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    CSCardPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    CSCardPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
