//
//  ReportCreationSuccessScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct ReportCreationSuccessScreen: View {
    let onViewReport: () -> Void
    let onReturnHome: () -> Void

    @State private var animateCheckmark = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                Image(systemName: "checkmark")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.white)
                    .padding(Theme.Spacing.cardPadding)
                    .background(Color.csGold, in: Circle())
                    .symbolEffect(
                        .bounce,
                        value: animateCheckmark
                    )
                    .accessibilityHidden(true)

                Text(verbatim: "Reporte enviado correctamente")
                    .font(.title2.bold())
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(
                    verbatim:
                        "Tu reporte ya es visible para la comunidad. Un administrador lo revisará para validarlo."
                )
                .font(.body)
                .foregroundStyle(Color.csTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

                StatusBadge(status: .pending)

                PrimaryButton(
                    title: "Ver mi reporte",
                    action: onViewReport
                )

                SecondaryButton(
                    title: "Volver al inicio",
                    action: onReturnHome
                )
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Reporte enviado"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
            animateCheckmark = true
        }
    }
}
