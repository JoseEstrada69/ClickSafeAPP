//
//  CommentComposerVIew.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

@MainActor
struct CommentComposerView: View {
    @Bindable var model: CommentComposerViewModel

    let onPublished: (Comment) async -> Void

    @State private var sendRequested = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard
        ) {
            TextField(
                "",
                text: $model.content,
                prompt: Text(verbatim: "Escribe un comentario…"),
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFieldStyle(.plain)
            .font(.body)
            .foregroundStyle(Color.csTextPrimary)
            .tint(Color.csNavy)
            .focused($isFocused)
            .padding(Theme.Spacing.withinCard)
            .frame(minHeight: Theme.Size.minimumTouchTarget)
            .background(
                Color.csSurface,
                in: RoundedRectangle(
                    cornerRadius: Theme.CornerRadius.field
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: Theme.CornerRadius.field
                )
                .strokeBorder(
                    isFocused ? Color.csGold : Color.csBorder,
                    lineWidth: isFocused
                        ? Theme.BorderWidth.focused
                        : Theme.BorderWidth.standard
                )
            }
            .accessibilityLabel(Text(verbatim: "Comentario"))
            .disabled(model.isSending || sendRequested)

            Text(verbatim: "\(model.characterCount)/1000")
                .font(.footnote)
                .foregroundStyle(
                    model.characterCount > 1000
                        ? Color.csDanger
                        : Color.csTextSecondary
                )
                .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(spacing: Theme.Spacing.withinCard) {
                Toggle(isOn: $model.isAnonymous) {
                    Text(verbatim: "Anónimo")
                        .font(.body)
                        .foregroundStyle(Color.csTextPrimary)
                }
                .tint(Color.csGold)
                .disabled(model.isSending || sendRequested)

                Button {
                    sendRequested = true
                } label: {
                    Group {
                        if model.isSending || sendRequested {
                            ProgressView()
                                .tint(Color.csOnNavy)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(Color.csOnNavy)
                    .frame(
                        width: Theme.Size.minimumTouchTarget,
                        height: Theme.Size.minimumTouchTarget
                    )
                    .background(
                        Color.csNavy,
                        in: RoundedRectangle(
                            cornerRadius: Theme.CornerRadius.button
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!model.canSubmit || sendRequested)
                .opacity(
                    model.canSubmit && !sendRequested
                        ? 1
                        : Theme.disabledOpacity
                )
                .accessibilityLabel(
                    Text(
                        verbatim: model.isSending || sendRequested
                            ? "Enviando comentario"
                            : "Enviar comentario"
                    )
                )
            }

            if let message = model.errorMessage {
                ErrorBanner(message: message) {
                    sendRequested = true
                }
                .disabled(!model.canSubmit || sendRequested)
            }
        }
        .padding(Theme.Spacing.screenMargin)
        .background(Color.csBackground)
        .task(id: sendRequested) {
            guard sendRequested else {
                return
            }

            if let comment = await model.submit() {
                isFocused = false
                await onPublished(comment)
            }

            guard !Task.isCancelled else {
                return
            }

            sendRequested = false
        }
        .onDisappear {
            sendRequested = false
        }
    }
}
