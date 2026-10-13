//
//  WelcomeView.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI

struct WelcomeView: View {
    let onLogin: () -> Void
    let onRegister: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Theme.Spacing.betweenBlocks) {
                    Spacer(minLength: Theme.Spacing.betweenBlocks)

                    VStack(spacing: Theme.Spacing.betweenBlocks) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.csNavy)
                            .accessibilityHidden(true)

                        Text(verbatim: "ClickSafe")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.csTextPrimary)
                            .accessibilityAddTraits(.isHeader)

                        Text(verbatim: "Consulta antes de comprar")
                            .font(.title2)
                            .foregroundStyle(Color.csTextPrimary)

                        Text(
                            verbatim: "Consulta reportes de posibles fraudes y comparte experiencias para ayudar a otros compradores."
                        )
                        .font(.body)
                        .foregroundStyle(Color.csTextSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: Theme.Spacing.betweenBlocks)

                    VStack(spacing: Theme.Spacing.withinCard) {
                        PrimaryButton(
                            title: "Iniciar sesión",
                            action: onLogin
                        )

                        SecondaryButton(
                            title: "Crear cuenta",
                            action: onRegister
                        )
                    }
                }
                .padding(Theme.Spacing.screenMargin)
                .frame(
                    minHeight: max(
                        0,
                        geometry.size.height
                            - Theme.Spacing.screenMargin * 2
                    )
                )
            }
        }
        .background(Color.csBackground.ignoresSafeArea())
    }
}

#Preview("Claro") {
    WelcomeView(onLogin: {}, onRegister: {})
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    WelcomeView(onLogin: {}, onRegister: {})
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    WelcomeView(onLogin: {}, onRegister: {})
        .environment(\.dynamicTypeSize, .accessibility3)
}
