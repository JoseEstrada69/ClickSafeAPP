//
//  ReportLinkCard.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
struct ReportedLinkCard: View {
    let rawURL: String

    @State private var showsWarning = false
    @State private var showsInvalidURL = false
    @State private var presentedLink: PresentedLink?
    @State private var copied = false

    private struct PresentedLink: Identifiable {
        let id = UUID()
        let url: URL
    }

    private var validatedURL: URL? {
        guard
            let components = URLComponents(string: rawURL),
            let scheme = components.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = components.host,
            !host.isEmpty,
            components.user == nil,
            components.password == nil,
            let url = components.url
        else {
            return nil
        }

        return url
    }

    private var domain: String {
        validatedURL?.host ?? "Enlace no válido"
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
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(Color.csGold)
                        .accessibilityHidden(true)

                    Text(verbatim: domain)
                        .font(.headline)
                        .foregroundStyle(Color.csTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(verbatim: rawURL)
                    .font(.footnote.monospaced())
                    .foregroundStyle(Color.csTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                SecondaryButton(title: "Copiar enlace") {
                    copyLink()
                }

                if copied {
                    Text(verbatim: "Enlace copiado.")
                        .font(.footnote)
                        .foregroundStyle(Color.csTextSecondary)
                }

                PrimaryButton(title: "Abrir con precaución") {
                    guard validatedURL != nil else {
                        showsInvalidURL = true
                        return
                    }

                    showsWarning = true
                }
            }
        }
        .alert(
            Text(verbatim: "Enlace reportado"),
            isPresented: $showsWarning
        ) {
            Button(role: .cancel) {
            } label: {
                Text(verbatim: "Cancelar")
            }

            Button {
                openLink()
            } label: {
                Text(verbatim: "Abrir")
            }
        } message: {
            Text(
                verbatim: "⚠️ Este enlace fue reportado como posible fraude. No inicies sesión, no descargues archivos y no ingreses datos personales ni de pago. ¿Abrir de todos modos?"
            )
        }
        .alert(
            Text(verbatim: "Enlace no válido"),
            isPresented: $showsInvalidURL
        ) {
            Button(role: .cancel) {
            } label: {
                Text(verbatim: "Aceptar")
            }
        } message: {
            Text(
                verbatim: "El enlace debe tener un dominio válido y utilizar HTTP o HTTPS."
            )
        }
        .sheet(item: $presentedLink) { link in
            ReportedLinkSafariView(url: link.url)
        }
        .onChange(of: rawURL) {
            copied = false
        }
    }

    private func copyLink() {
        guard validatedURL != nil else {
            showsInvalidURL = true
            return
        }

        UIPasteboard.general.setItems(
            [[UTType.plainText.identifier: rawURL]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(120)
            ]
        )

        copied = true
    }

    private func openLink() {
        guard let url = validatedURL else {
            showsInvalidURL = true
            return
        }

        presentedLink = PresentedLink(url: url)
    }
}
