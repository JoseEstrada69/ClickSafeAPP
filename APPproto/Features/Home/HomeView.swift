//
//  HomeView.swift
//  APPproto
//
//  Created by Carlos Emilio Romero Rubio on 29/10/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.betweenBlocks) {
                header
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

            Text(verbatim: "Bienvenido a ClickSafe")
                .font(.title2.bold())
                .foregroundStyle(Color.csTextPrimary)

            Text(verbatim: "Consulta y reporta vendedores antes de comprar en línea.")
                .font(.body)
                .foregroundStyle(Color.csTextSecondary)
        }
    }
}

#Preview("Claro") {
    NavigationStack {
        HomeView()
    }
    .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    NavigationStack {
        HomeView()
    }
    .preferredColorScheme(.dark)
}
