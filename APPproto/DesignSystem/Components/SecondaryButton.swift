//
//  SecondaryButton.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 05/10/26.
//

import SwiftUI

struct SecondaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.csNavy)
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
                        Color.csNavy,
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

private struct SecondaryButtonPreview: View {
    @State private var tapCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                SecondaryButton(title: "Volver") {
                    tapCount += 1
                }

                Text("Pulsaciones: \(tapCount)")
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)

                SecondaryButton(title: "No disponible") {
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
    SecondaryButtonPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    SecondaryButtonPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    SecondaryButtonPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
