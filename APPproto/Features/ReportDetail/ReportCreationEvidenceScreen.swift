//
//  ReportCreationEvidenceScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import PhotosUI
import SwiftUI
import UIKit

@MainActor
struct ReportCreationEvidenceScreen: View {
    let model: ReportCreationViewModel
    let onBack: () -> Void
    let onSubmitted: (Report) -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var processingRequested = false
    @State private var sendRequested = false

    private var isBusy: Bool {
        model.isBusy || processingRequested || sendRequested
    }

    private var isSending: Bool {
        sendRequested || model.isSending
    }

    private var imageColumns: [GridItem] {
        [
            GridItem(
                .adaptive(
                    minimum: Theme.Size.evidenceThumbnail
                ),
                spacing: Theme.Spacing.withinCard
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                Text(verbatim: "Paso 2 de 2")
                    .font(.subheadline)
                    .foregroundStyle(Color.csTextSecondary)

                privacyNotice

                Text(
                    verbatim: "\(model.draft.evidences.count) de 5 imágenes"
                )
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)

                if !model.draft.evidences.isEmpty {
                    LazyVGrid(
                        columns: imageColumns,
                        spacing: Theme.Spacing.withinCard
                    ) {
                        ForEach(model.draft.evidences) { evidence in
                            evidenceThumbnail(evidence)
                        }
                    }
                }

                if model.remainingImageSlots > 0 {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: model.remainingImageSlots,
                        matching: .images
                    ) {
                        Label {
                            Text(verbatim: "Seleccionar fotografías")
                        } icon: {
                            Image(systemName: "photo.on.rectangle")
                        }
                        .font(.headline)
                        .foregroundStyle(Color.csNavy)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: Theme.Size.minimumTouchTarget
                        )
                        .contentShape(Rectangle())
                    }
                    .disabled(isBusy)
                }

                if processingRequested || model.isProcessingImages {
                    ProgressView {
                        Text(verbatim: "Preparando imágenes…")
                    }
                    .frame(maxWidth: .infinity)
                }

                reportSummary

                if let message = model.errorMessage {
                    Text(verbatim: message)
                        .font(.body)
                        .foregroundStyle(Color.csDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LoadingButton(
                    title: "Enviar reporte",
                    isLoading: isSending,
                    loadingTitle: "Enviando reporte…"
                ) {
                    guard model.canSubmit, !isBusy else { return }
                    sendRequested = true
                }
                .disabled(!model.canSubmit || isBusy)

                SecondaryButton(title: "Volver") {
                    guard !isBusy else { return }
                    onBack()
                }
                .disabled(isBusy)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Agregar evidencia"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isBusy)
        .interactiveDismissDisabled(isBusy)
        .onChange(of: selectedItems) { _, items in
            guard !items.isEmpty, !isBusy else { return }
            processingRequested = true
        }
        .task(id: processingRequested) {
            guard processingRequested else { return }

            await model.processImages(selectedItems)

            selectedItems = []
            processingRequested = false
        }
        .task(id: sendRequested) {
            guard sendRequested else { return }

            let report = await model.submit()

            guard !Task.isCancelled else { return }

            sendRequested = false

            if let report {
                onSubmitted(report)
            }
        }
    }

    private var privacyNotice: some View {
        HStack(
            alignment: .top,
            spacing: Theme.Spacing.withinCard
        ) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(Color.csGold)
                .accessibilityHidden(true)

            Text(
                verbatim:
                    "Tus imágenes serán públicas. Antes de subirlas, tapa o recorta números de tarjeta, direcciones, teléfonos, correos y cualquier dato personal."
            )
            .font(.body)
            .foregroundStyle(Color.csTextPrimary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.cardPadding)
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
                Color.csGold,
                lineWidth: Theme.BorderWidth.standard
            )
        }
    }

    private var reportSummary: some View {
        CSCard {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.withinCard
            ) {
                Text(verbatim: "Resumen del reporte")
                    .font(.headline)
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                summaryLine(
                    title: "Plataforma",
                    value: model.selectedPlatformIsOther
                        ? model.draft.otherPlatform
                        : model.selectedPlatform?.nombre ?? ""
                )

                summaryLine(
                    title: "Tipo de fraude",
                    value: model.selectedCategory?.nombre ?? ""
                )

                summaryLine(
                    title: "Publicación anónima",
                    value: model.draft.isAnonymous ? "Sí" : "No"
                )

                summaryLine(
                    title: "Dominio del enlace",
                    value: model.publicationDomain ?? ""
                )
            }
        }
    }

    private func summaryLine(
        title: String,
        value: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard / 2
        ) {
            Text(verbatim: title)
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)

            Text(verbatim: value)
                .font(.body)
                .foregroundStyle(Color.csTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func evidenceThumbnail(
        _ evidence: PendingEvidence
    ) -> some View {
        VStack(spacing: Theme.Spacing.withinCard) {
            Group {
                if let image = UIImage(data: evidence.jpegData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(Color.csTextSecondary)
                }
            }
            .frame(
                width: Theme.Size.evidenceThumbnail,
                height: Theme.Size.evidenceThumbnail
            )
            .background(Color.csPlaceholderImage)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.CornerRadius.thumbnail
                )
            )
            .accessibilityLabel(
                Text(verbatim: "Imagen seleccionada")
            )

            Button {
                guard !isBusy else { return }
                model.removeImage(id: evidence.id)
            } label: {
                Label {
                    Text(verbatim: "Quitar")
                } icon: {
                    Image(systemName: "xmark.circle.fill")
                }
                .font(.footnote)
                .frame(
                    minHeight: Theme.Size.minimumTouchTarget
                )
            }
            .foregroundStyle(Color.csNavy)
            .disabled(isBusy)
            .accessibilityLabel(
                Text(verbatim: "Quitar imagen seleccionada")
            )
        }
    }
}
