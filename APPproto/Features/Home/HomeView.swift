//
//  HomeView.swift
//  APPproto
//
//  Created by Carlos Emilio Romero Rubio on 29/10/26.
//

import SwiftUI

struct HomeView: View {
    let onReport: () -> Void
    let onSearch: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.betweenBlocks) {
                header
                quickActions
                SafetyTipsCard(tips: SafetyTip.defaults)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .background(Color.csBackground)
        .navigationTitle(Text(verbatim: "Inicio"))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.withinCard) {
            Image(systemName: "checkmark.shield.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.csNavy)
                .accessibilityHidden(true)

            Text(verbatim: "Bienvenido a ClickSafe")
                .font(.title2.bold())
                .foregroundStyle(Color.csTextPrimary)

            Text(verbatim: "Consulta y reporta vendedores antes de comprar en línea.")
                .font(.body)
                .foregroundStyle(Color.csTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var quickActions: some View {
        CSCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.withinCard) {
                Text(verbatim: "¿Qué quieres hacer?")
                    .font(.headline)
                    .foregroundStyle(Color.csTextPrimary)

                PrimaryButton(title: "Reportar posible fraude", action: onReport)
                    .accessibilityHint(Text(verbatim: "Abre la pestaña Reportar"))

                SecondaryButton(title: "Buscar un reporte", action: onSearch)
                    .accessibilityHint(Text(verbatim: "Abre la pestaña Buscar"))
            }
        }
    }
}

#Preview("Claro") {
    NavigationStack {
        HomeView(onReport: {}, onSearch: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    NavigationStack {
        HomeView(onReport: {}, onSearch: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    NavigationStack {
        HomeView(onReport: {}, onSearch: {})
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
