//
//  EvidenceViewer.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct EvidenceViewer: View {
    let evidences: [Evidence]
    let baseURL: URL?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: Int

    init(
        evidences: [Evidence],
        selectedID: Int,
        baseURL: URL?
    ) {
        self.evidences = evidences
        self.baseURL = baseURL

        let initialID = evidences.contains {
            $0.id == selectedID
        } ? selectedID : evidences.first?.id ?? selectedID

        _selectedID = State(initialValue: initialID)
    }

    private var positionTitle: String {
        guard let index = evidences.firstIndex(
            where: { $0.id == selectedID }
        ) else {
            return "Evidencias"
        }

        return "\(index + 1) de \(evidences.count)"
    }

    var body: some View {
        NavigationStack {
            Group {
                if evidences.isEmpty {
                    EmptyStateView(
                        symbol: "photo",
                        title: "Sin evidencias",
                        message: "Este reporte no tiene imágenes."
                    )
                } else {
                    TabView(selection: $selectedID) {
                        ForEach(evidences) { evidence in
                            EvidenceImagePage(
                                evidence: evidence,
                                baseURL: baseURL
                            )
                            .tag(evidence.id)
                        }
                    }
                    .tabViewStyle(
                        .page(indexDisplayMode: .never)
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background(Color.csBackground.ignoresSafeArea())
            .navigationTitle(Text(verbatim: positionTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(verbatim: "Cerrar")
                    }
                }
            }
        }
        .tint(Color.csNavy)
    }
}

@MainActor
private struct EvidenceImagePage: View {
    let evidence: Evidence
    let baseURL: URL?

    @Environment(\.mockEvidenceImagesEnabled)
    private var mockEvidenceImagesEnabled

    @State private var retryID = UUID()

    private var evidenceURL: URL? {
        EvidenceURLValidator.resolve(
            path: evidence.url,
            baseURL: baseURL
        )
    }

    var body: some View {
        Group {
            if let image = MockEvidenceImageSource.image(
                from: evidence.url,
                enabled: mockEvidenceImagesEnabled
            ) {
                ZoomableEvidenceImage(
                    image: Image(uiImage: image)
                )
            } else if let url = evidenceURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .accessibilityLabel(
                                Text(verbatim: "Cargando evidencia")
                            )

                    case .success(let image):
                        ZoomableEvidenceImage(image: image)

                    case .failure:
                        ErrorBanner(
                            message: "No se pudo cargar la evidencia."
                        ) {
                            retryID = UUID()
                        }
                        .padding(Theme.Spacing.screenMargin)

                    @unknown default:
                        unavailableView
                    }
                }
                .id(retryID)
            } else {
                unavailableView
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    private var unavailableView: some View {
        EmptyStateView(
            symbol: "photo.badge.exclamationmark",
            title: "Evidencia no disponible",
            message: "No se pudo obtener una imagen válida."
        )
    }
}
