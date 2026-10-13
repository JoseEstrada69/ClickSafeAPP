//
//  ReportLikeView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct ReportLikeView: View {
    let model: ReportLikeViewModel

    @State private var updateRequested = false

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard
        ) {
            Button {
                updateRequested = true
            } label: {
                HStack(spacing: Theme.Spacing.withinCard) {
                    Image(
                        systemName: model.likedByMe
                            ? "hand.thumbsup.fill"
                            : "hand.thumbsup"
                    )
                    .accessibilityHidden(true)

                    Text(verbatim: "Me pasó algo similar")
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

                    Spacer()

                    Text(verbatim: "\(model.totalLikes)")
                }
                .font(.headline)
                .foregroundStyle(Color.csNavy)
                .frame(
                    minHeight: Theme.Size.minimumTouchTarget
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(
                model.isOwnReport
                    || model.isUpdating
                    || updateRequested
            )
            .opacity(
                model.isOwnReport ? Theme.disabledOpacity : 1
            )
            .accessibilityLabel(
                Text(verbatim: "Me pasó algo similar")
            )
            .accessibilityValue(
                Text(
                    verbatim: "\(model.totalLikes) me gusta. "
                        + (model.likedByMe
                            ? "Tu reacción está activada."
                            : "Tu reacción está desactivada.")
                )
            )

            if model.isOwnReport {
                Text(
                    verbatim: "No puedes reaccionar a tu propio reporte."
                )
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)
            }

            if model.isUpdating {
                ProgressView()
                    .accessibilityLabel(
                        Text(verbatim: "Actualizando reacción")
                    )
            }

            if let message = model.errorMessage {
                ErrorBanner(message: message) {
                    updateRequested = true
                }
                .disabled(
                    model.isUpdating || updateRequested
                )
            }
        }
        .task(id: updateRequested) {
            guard updateRequested else {
                return
            }

            await model.toggleLike()

            guard !Task.isCancelled else {
                return
            }

            updateRequested = false
        }
        .onDisappear {
            updateRequested = false
        }
    }
}
