//
//  ReportReviewCard.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

struct ReportReviewCard: View {
    let review: Review

    private var badgeStatus: StatusBadge.Status {
        switch review.decision {
        case .pending:
            return .pending
        case .validated:
            return .validated
        case .rejected:
            return .rejected
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: review.fecha)
    }

    var body: some View {
        CSCard {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.withinCard
            ) {
                Text(verbatim: "Revisión de ClickSafe")
                    .font(.headline)
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                StatusBadge(status: badgeStatus)

                if let comment = review.comentario,
                   !comment.trimmingCharacters(
                       in: .whitespacesAndNewlines
                   ).isEmpty {
                    Text(verbatim: comment)
                        .font(.body)
                        .foregroundStyle(Color.csTextPrimary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Text(verbatim: formattedDate)
                    .font(.footnote)
                    .foregroundStyle(Color.csTextSecondary)
            }
        }
    }
}
