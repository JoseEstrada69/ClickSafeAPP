//
//  ReportEvidenceSection.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

private struct EvidenceBaseURLKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

extension EnvironmentValues {
    var evidenceBaseURL: URL? {
        get { self[EvidenceBaseURLKey.self] }
        set { self[EvidenceBaseURLKey.self] = newValue }
    }
}

@MainActor
struct ReportEvidenceSection: View {
    let evidences: [Evidence]

    @Environment(\.evidenceBaseURL) private var baseURL
    @State private var selectedEvidence: Evidence?

    var body: some View {
        Section {
            if evidences.isEmpty {
                Text(verbatim: "Este reporte no tiene evidencias.")
                    .font(.body)
                    .foregroundStyle(Color.csTextSecondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: Theme.Spacing.withinCard) {
                        ForEach(
                            Array(evidences.enumerated()),
                            id: \.element.id
                        ) { index, evidence in
                            Button {
                                selectedEvidence = evidence
                            } label: {
                                EvidenceThumbnail(
                                    path: evidence.url,
                                    baseURL: baseURL,
                                    accessibilityDescription:
                                        "Evidencia \(index + 1) de \(evidences.count)"
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(
                                Text(verbatim: "Abrir imagen a pantalla completa")
                            )
                        }
                    }
                    .padding(.vertical, Theme.Spacing.withinCard)
                }
            }
        } header: {
            Text(verbatim: "Evidencias")
        }
        .listRowBackground(Color.csSurface)
        .fullScreenCover(item: $selectedEvidence) { evidence in
            EvidenceViewer(
                evidences: evidences,
                selectedID: evidence.id,
                baseURL: baseURL
            )
        }
    }
}
