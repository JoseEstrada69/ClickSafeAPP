//
//  ReportEvidenceEditView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import PhotosUI
import SwiftUI
import UIKit

@MainActor
struct ReportEvidenceEditView: View {
    let model: ReportEvidenceEditViewModel
    let onChanged: () async -> Void

    @Environment(\.evidenceBaseURL) private var evidenceBaseURL

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var processingRequested = false
    @State private var uploadRequested = false
    @State private var evidenceToDelete: Evidence?
    @State private var deletionRequested: Evidence?

    private var isBusy: Bool {
        model.isBusy
            || processingRequested
            || uploadRequested
            || deletionRequested != nil
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.betweenBlocks
        ) {
            Text(verbatim: "Evidencias")
                .font(.headline)
                .foregroundStyle(Color.csTextPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(
                verbatim:
                    "Tus imágenes serán públicas. Antes de subirlas, tapa o recorta números de tarjeta, direcciones, teléfonos, correos y cualquier dato personal."
            )
            .font(.footnote)
            .foregroundStyle(Color.csTextPrimary)
            .fixedSize(horizontal: false, vertical: true)
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
                    Color.csGold,
                    lineWidth: Theme.BorderWidth.standard
                )
            }

            Text(
                verbatim: "\(model.totalImageCount) de 5 imágenes"
            )
            .font(.footnote)
            .foregroundStyle(Color.csTextSecondary)

            if !model.evidences.isEmpty {
                existingEvidences
            }

            if !model.pendingImages.isEmpty {
                pendingEvidences
            }

            if model.remainingSlots > 0,
               !model.isNoLongerEditable {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: model.remainingSlots,
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

            if !model.pendingImages.isEmpty {
                PrimaryButton(title: "Subir imágenes seleccionadas") {
                    uploadRequested = true
                }
                .disabled(!model.canUpload || isBusy)
            }

            if isBusy {
                ProgressView(
                    uploadRequested
                        ? "Subiendo imágenes…"
                        : deletionRequested != nil
                            ? "Eliminando evidencia…"
                            : "Preparando imágenes…"
                )
                .frame(maxWidth: .infinity)
            }

            if let errorMessage = model.errorMessage {
                Text(verbatim: errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.csDanger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: selectedItems) { _, items in
            guard !items.isEmpty, !isBusy else {
                return
            }

            processingRequested = true
        }
        .task(id: processingRequested) {
            guard processingRequested else {
                return
            }

            await model.process(selectedItems)
            selectedItems = []
            processingRequested = false
        }
        .task(id: uploadRequested) {
            guard uploadRequested else {
                return
            }

            if await model.upload() != nil {
                await onChanged()
            }

            uploadRequested = false
        }
        .task(id: deletionRequested?.id) {
            guard let evidence = deletionRequested else {
                return
            }

            if await model.delete(evidence) {
                await onChanged()
            }

            deletionRequested = nil
        }
        .confirmationDialog(
            "¿Eliminar esta evidencia?",
            isPresented: Binding(
                get: { evidenceToDelete != nil },
                set: { isPresented in
                    if !isPresented {
                        evidenceToDelete = nil
                    }
                }
            ),
            titleVisibility: .visible,
            presenting: evidenceToDelete
        ) { evidence in
            Button("Eliminar evidencia", role: .destructive) {
                deletionRequested = evidence
                evidenceToDelete = nil
            }

            Button("Cancelar", role: .cancel) {
                evidenceToDelete = nil
            }
        } message: { _ in
            Text("Esta acción no se puede deshacer.")
        }
    }

    private var existingEvidences: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard
        ) {
            Text(verbatim: "Imágenes publicadas")
                .font(.subheadline)
                .foregroundStyle(Color.csTextPrimary)

            ScrollView(.horizontal) {
                HStack(
                    alignment: .top,
                    spacing: Theme.Spacing.withinCard
                ) {
                    ForEach(model.evidences) { evidence in
                        VStack(spacing: Theme.Spacing.withinCard) {
                            EvidenceThumbnail(
                                path: evidence.url,
                                baseURL: evidenceBaseURL
                            )

                            Button(role: .destructive) {
                                evidenceToDelete = evidence
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                                    .font(.footnote)
                                    .frame(
                                        minHeight:
                                            Theme.Size.minimumTouchTarget
                                    )
                            }
                            .disabled(
                                isBusy || model.isNoLongerEditable
                            )
                            .accessibilityLabel(
                                "Eliminar evidencia publicada"
                            )
                        }
                    }
                }
            }
        }
    }

    private var pendingEvidences: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard
        ) {
            Text(verbatim: "Imágenes pendientes de subir")
                .font(.subheadline)
                .foregroundStyle(Color.csTextPrimary)

            ScrollView(.horizontal) {
                HStack(
                    alignment: .top,
                    spacing: Theme.Spacing.withinCard
                ) {
                    ForEach(model.pendingImages) { image in
                        VStack(spacing: Theme.Spacing.withinCard) {
                            pendingThumbnail(image)

                            Button {
                                model.removePending(id: image.id)
                            } label: {
                                Label(
                                    "Quitar",
                                    systemImage: "xmark.circle"
                                )
                                .font(.footnote)
                                .frame(
                                    minHeight:
                                        Theme.Size.minimumTouchTarget
                                )
                            }
                            .foregroundStyle(Color.csNavy)
                            .disabled(isBusy)
                            .accessibilityLabel(
                                "Quitar imagen pendiente de subir"
                            )
                        }
                    }
                }
            }
        }
    }

    private func pendingThumbnail(
        _ evidence: PendingEvidence
    ) -> some View {
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
        .accessibilityLabel("Imagen pendiente de subir")
    }
}
