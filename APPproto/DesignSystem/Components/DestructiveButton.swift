//
//  DestructiveButton.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 05/10/26.
//

import SwiftUI

struct DestructiveButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text(verbatim: title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.csDanger)
                .padding(.horizontal, Theme.Spacing.withinCard)
                .padding(.vertical, Theme.Spacing.withinCard)
                .frame(
                    maxWidth: .infinity,
                    minHeight: Theme.Size.minimumButtonHeight
                )
                .background(
                    Color.csSurface,
                    in: RoundedRectangle(
                        cornerRadius: Theme.CornerRadius.button
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: Theme.CornerRadius.button
                    )
                    .strokeBorder(
                        Color.csDanger,
                        lineWidth: Theme.BorderWidth.standard
                    )
                }
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: Theme.CornerRadius.button
                    )
                )
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : Theme.disabledOpacity)
    }
}

private struct DestructiveButtonPreview: View {
    @State private var tapCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                DestructiveButton(title: "Eliminar reporte") {
                    tapCount += 1
                }

                Text("Pulsaciones: \(tapCount)")
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)

                DestructiveButton(title: "No disponible") {
                    tapCount += 1
                }
                .disabled(true)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    DestructiveButtonPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    DestructiveButtonPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    DestructiveButtonPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
