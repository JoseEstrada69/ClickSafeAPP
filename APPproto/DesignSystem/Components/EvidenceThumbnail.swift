//
//  EvidenceThumbnail.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

@MainActor
struct EvidenceThumbnail: View {
    let path: String?
    let baseURL: URL?
    var accessibilityDescription: String = "Imagen de evidencia"

    @Environment(\.mockEvidenceImagesEnabled)
    private var mockEvidenceImagesEnabled

    private var evidenceURL: URL? {
        EvidenceURLValidator.resolve(
            path: path,
            baseURL: baseURL
        )
    }

    var body: some View {
        Group {
            if let image = MockEvidenceImageSource.image(
                from: path,
                enabled: mockEvidenceImagesEnabled
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel(
                        Text(verbatim: accessibilityDescription)
                    )
            } else if let evidenceURL {
                AsyncImage(url: evidenceURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .accessibilityLabel(
                                "Cargando evidencia"
                            )

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .accessibilityLabel(
                                Text(
                                    verbatim: accessibilityDescription
                                )
                            )

                    case .failure:
                        placeholder(
                            symbol: "photo.badge.exclamationmark",
                            label: "No se pudo cargar la evidencia"
                        )

                    @unknown default:
                        placeholder(
                            symbol: "photo",
                            label: "Evidencia no disponible"
                        )
                    }
                }
            } else {
                placeholder(
                    symbol: "photo",
                    label: "Evidencia no disponible"
                )
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
    }

    private func placeholder(
        symbol: String,
        label: String
    ) -> some View {
        ZStack {
            Color.csPlaceholderImage

            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.csTextSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label))
    }
}

private struct EvidenceThumbnailPreview: View {
    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                Text(verbatim: "Evidencia sin cargar")
                    .font(.headline)
                    .foregroundStyle(Color.csTextPrimary)

                EvidenceThumbnail(
                    path: nil,
                    baseURL: nil
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    EvidenceThumbnailPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    EvidenceThumbnailPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    EvidenceThumbnailPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
