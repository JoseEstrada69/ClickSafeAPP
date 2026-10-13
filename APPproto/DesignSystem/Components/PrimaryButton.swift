//
//  PrimaryButton.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 05/10/26.
//

import SwiftUI

struct PrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.csOnNavy)
                .padding(.horizontal, Theme.Spacing.withinCard)
                .padding(.vertical, Theme.Spacing.withinCard)
                .frame(
                    maxWidth: .infinity,
                    minHeight: Theme.Size.minimumButtonHeight
                )
                .background(
                    Color.csNavy,
                    in: RoundedRectangle(
                        cornerRadius: Theme.CornerRadius.button
                    )
                )
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

private struct PrimaryButtonPreview: View {
    @State private var tapCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                PrimaryButton(title: "Continuar") {
                    tapCount += 1
                }

                Text("Pulsaciones: \(tapCount)")
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)

                PrimaryButton(title: "No disponible") {
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
    PrimaryButtonPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    PrimaryButtonPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    PrimaryButtonPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
