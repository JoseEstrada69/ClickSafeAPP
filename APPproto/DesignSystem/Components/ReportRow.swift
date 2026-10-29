//
//  ReportRow.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import SwiftUI

struct ReportRow: View {
    let title: String
    let platform: String
    let category: String
    let date: Date
    let status: StatusBadge.Status
    let likeCount: Int

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        CSCard {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.withinCard
            ) {
                HStack(
                    alignment: .top,
                    spacing: Theme.Spacing.withinCard
                ) {
                    Text(verbatim: title)
                        .font(.headline)
                        .foregroundStyle(Color.csTextPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(Text(verbatim: title))

                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(Color.csTextSecondary)
                        .accessibilityHidden(true)
                }

                Text(
                    verbatim: "\(platform) • \(category) • \(formattedDate)"
                )
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

                StatusBadge(status: status)

                HStack(spacing: Theme.Spacing.withinCard / 2) {
                    Image(systemName: "hand.thumbsup")
                        .accessibilityHidden(true)

                    Text(verbatim: "\(likeCount)")
                }
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    Text(verbatim: "\(likeCount) me gusta")
                )
            }
        }
    }
}

private struct ReportRowPreview: View {
    @State private var selectionCount = 0

    private let sampleDate = Date(timeIntervalSince1970: 1_791_288_000)

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                Button {
                    selectionCount += 1
                } label: {
                    ReportRow(
                        title: "Reporte de ejemplo sobre una publicación",
                        platform: "Plataforma de ejemplo",
                        category: "Categoría de ejemplo",
                        date: sampleDate,
                        status: .pending,
                        likeCount: 3
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Ver el detalle del reporte")

                ReportRow(
                    title: "Otro reporte de ejemplo",
                    platform: "Plataforma de ejemplo",
                    category: "Categoría de ejemplo",
                    date: sampleDate,
                    status: .validated,
                    likeCount: 12
                )

                ReportRow(
                    title: "Reporte de ejemplo con un título largo para comprobar el límite de dos líneas",
                    platform: "Plataforma de ejemplo",
                    category: "Categoría de ejemplo",
                    date: sampleDate,
                    status: .rejected,
                    likeCount: 0
                )

                Text(
                    verbatim: "Reportes seleccionados: \(selectionCount)"
                )
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    ReportRowPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    ReportRowPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    ReportRowPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
