//
//  CommentFlagScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct CommentFlagScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: CommentFlagViewModel
    @State private var sendRequested = false
    @State private var showsResult = false

    init(comment: Comment, api: any APIClient) {
        _model = State(
            initialValue: CommentFlagViewModel(
                comment: comment,
                api: api
            )
        )
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.betweenBlocks
                ) {
                    Text(
                        verbatim: "Selecciona el motivo de la denuncia."
                    )
                    .font(.body)
                    .foregroundStyle(Color.csTextPrimary)

                    Picker(selection: $model.reason) {
                        ForEach(CommentFlagReason.allCases) { reason in
                            Text(verbatim: reason.title)
                                .tag(reason)
                        }
                    } label: {
                        Text(verbatim: "Motivo")
                    }
                    .pickerStyle(.menu)
                    .tint(Color.csNavy)
                    .frame(
                        minHeight: Theme.Size.minimumTouchTarget
                    )
                    .disabled(model.isSending || sendRequested)

                    VStack(
                        alignment: .leading,
                        spacing: Theme.Spacing.withinCard
                    ) {
                        Text(verbatim: "Detalle opcional")
                            .font(.subheadline)
                            .foregroundStyle(Color.csTextPrimary)

                        TextField(
                            "",
                            text: $model.detail,
                            prompt: Text(
                                verbatim: "Agrega información sobre el motivo…"
                            ),
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundStyle(Color.csTextPrimary)
                        .tint(Color.csNavy)
                        .padding(Theme.Spacing.withinCard)
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
                                Color.csBorder,
                                lineWidth: Theme.BorderWidth.standard
                            )
                        }
                        .accessibilityLabel(
                            Text(verbatim: "Detalle opcional")
                        )
                        .disabled(model.isSending || sendRequested)

                        Text(verbatim: "\(model.detail.count)/255")
                            .font(.footnote)
                            .foregroundStyle(
                                model.detail.count > 255
                                    ? Color.csDanger
                                    : Color.csTextSecondary
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .trailing
                            )
                    }

                    if let message = model.errorMessage {
                        ErrorBanner(message: message) {
                            sendRequested = true
                        }
                        .disabled(
                            !model.canSubmit || sendRequested
                        )
                    }

                    PrimaryButton(
                        title: model.isSending || sendRequested
                            ? "Enviando…"
                            : "Enviar denuncia"
                    ) {
                        sendRequested = true
                    }
                    .disabled(!model.canSubmit || sendRequested)

                    if model.isSending || sendRequested {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(
                                Text(verbatim: "Enviando denuncia")
                            )
                    }
                }
                .padding(Theme.Spacing.screenMargin)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.csBackground.ignoresSafeArea())
            .navigationTitle(Text(verbatim: "Denunciar comentario"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(verbatim: "Cancelar")
                    }
                    .disabled(model.isSending || sendRequested)
                }
            }
        }
        .interactiveDismissDisabled(
            model.isSending || sendRequested
        )
        .task(id: sendRequested) {
            guard sendRequested else {
                return
            }

            await model.submit()

            guard !Task.isCancelled else {
                return
            }

            sendRequested = false
            showsResult = model.resultMessage != nil
        }
        .alert(
            Text(verbatim: "Denuncia"),
            isPresented: $showsResult
        ) {
            Button {
                dismiss()
            } label: {
                Text(verbatim: "Aceptar")
            }
        } message: {
            Text(verbatim: model.resultMessage ?? "")
        }
        .onDisappear {
            sendRequested = false
        }
    }
}
