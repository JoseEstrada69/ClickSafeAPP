//
//  ChevronRow.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

struct ChevronRow: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    var value: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.withinCard) {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.Spacing.withinCard
                    ) {
                        titleText

                        if !value.isEmpty {
                            valueText
                        }
                    }

                    Spacer(minLength: 0)
                } else {
                    titleText

                    Spacer(minLength: Theme.Spacing.withinCard)

                    if !value.isEmpty {
                        valueText
                            .multilineTextAlignment(.trailing)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(Color.csTextSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Theme.Spacing.withinCard)
            .frame(
                maxWidth: .infinity,
                minHeight: Theme.Size.minimumTouchTarget,
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityValue(Text(verbatim: value))
        .opacity(isEnabled ? 1 : Theme.disabledOpacity)
    }

    private var titleText: some View {
        Text(verbatim: title)
            .font(.body)
            .foregroundStyle(Color.csTextPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var valueText: some View {
        Text(verbatim: value)
            .font(.body)
            .foregroundStyle(Color.csTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ChevronRowPreview: View {
    @State private var tapCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                CSCard {
                    VStack(spacing: Theme.Spacing.withinCard) {
                        ChevronRow(
                            title: "Plataforma",
                            value: "Seleccionar"
                        ) {
                            tapCount += 1
                        }

                        ChevronRow(title: "Mis reportes") {
                            tapCount += 1
                        }

                        ChevronRow(
                            title: "No disponible",
                            value: "Seleccionar"
                        ) {
                            tapCount += 1
                        }
                        .disabled(true)
                    }
                }

                Text("Pulsaciones: \(tapCount)")
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    ChevronRowPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    ChevronRowPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    ChevronRowPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
