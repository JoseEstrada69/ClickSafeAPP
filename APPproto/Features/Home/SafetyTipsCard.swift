//
//  SafetyTipsCard.swift
//  APPproto
//
//  Created by Carlos Emilio Romero Rubio on 29/10/26.
//

import SwiftUI

struct SafetyTip: Identifiable, Hashable {
    let id: Int
    let text: String

    static let defaults: [SafetyTip] = [
        SafetyTip(id: 1, text: "Desconfía de precios demasiado bajos."),
        SafetyTip(id: 2, text: "Nunca pagues fuera de la plataforma de venta."),
        SafetyTip(id: 3, text: "Revisa la reputación del vendedor antes de comprar.")
    ]
}

struct SafetyTipsCard: View {
    let tips: [SafetyTip]

    var body: some View {
        CSCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.withinCard) {
                Text(verbatim: "Consejos para comprar seguro")
                    .font(.headline)
                    .foregroundStyle(Color.csTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                ForEach(tips) { tip in
                    Label {
                        Text(verbatim: tip.text)
                            .font(.body)
                            .foregroundStyle(Color.csTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "lightbulb")
                            .foregroundStyle(Color.csGold)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }
}

#Preview {
    SafetyTipsCard(tips: SafetyTip.defaults)
        .padding(Theme.Spacing.screenMargin)
        .background(Color.csBackground)
}
