//
//  LoadingButton.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 05/10/26.
//

import SwiftUI

struct LoadingButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let isLoading: Bool
    var loadingTitle: String = "Verificando…"
    let action: () -> Void

    var body: some View {
        Button {
            guard isEnabled, !isLoading else { return }
            action()
        } label: {
            HStack(spacing: Theme.Spacing.withinCard) {
                if isLoading {
                    ProgressView()
                        .tint(Color.csOnNavy)
                        .accessibilityHidden(true)
                }

                Text(verbatim: isLoading ? loadingTitle : title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
        .disabled(isLoading)
        .opacity(isEnabled ? 1 : Theme.disabledOpacity)
    }
}

private struct LoadingButtonPreview: View {
    @State private var isLoading = false
    @State private var requestCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                LoadingButton(
                    title: "Enviar reporte",
                    isLoading: isLoading,
                    loadingTitle: "Enviando reporte…"
                ) {
                    isLoading = true
                    requestCount += 1
                }

                Text(
                    verbatim: "Solicitudes iniciadas: \(requestCount)"
                )
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)

                Button {
                    isLoading = false
                } label: {
                    Text(verbatim: "Finalizar prueba")
                }
                .font(.headline)
                .foregroundStyle(Color.csNavy)
                .frame(
                    minHeight: Theme.Size.minimumTouchTarget
                )
                .disabled(!isLoading)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    LoadingButtonPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    LoadingButtonPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    LoadingButtonPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
