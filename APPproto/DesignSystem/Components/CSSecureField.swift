//
//  CSSecureField.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 05/10/26.
//

import SwiftUI

struct CSSecureField: View {
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var isFocused: Bool

    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var errorMessage: String? = nil

    private var borderColor: Color {
        if isFocused {
            return .csGold
        }

        return errorMessage == nil ? .csBorder : .csDanger
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard
        ) {
            Text(verbatim: title)
                .font(.subheadline)
                .foregroundStyle(Color.csTextPrimary)
                .accessibilityHidden(true)

            SecureField(
                title,
                text: $text,
                prompt: Text(verbatim: placeholder)
                    .foregroundStyle(Color.csTextSecondary)
            )
            .textFieldStyle(.plain)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.body)
            .foregroundStyle(Color.csTextPrimary)
            .tint(Color.csNavy)
            .focused($isFocused)
            .padding(Theme.Spacing.withinCard)
            .frame(minHeight: Theme.Size.minimumTouchTarget)
            .background(
                Color.csSurface,
                in: RoundedRectangle(
                    cornerRadius: Theme.CornerRadius.field
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: Theme.CornerRadius.field
                )
                .strokeBorder(
                    borderColor,
                    lineWidth: isFocused
                        ? Theme.BorderWidth.focused
                        : Theme.BorderWidth.standard
                )
            }
            .accessibilityLabel(Text(verbatim: title))
            .accessibilityHint(
                Text(verbatim: errorMessage ?? "")
            )

            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.csDanger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(isEnabled ? 1 : Theme.disabledOpacity)
    }
}

private struct CSSecureFieldPreview: View {
    @State private var password = ""
    @State private var confirmation = ""
    @State private var disabledPassword = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                CSSecureField(
                    title: "Contraseña",
                    text: $password,
                    placeholder: "Escribe tu contraseña"
                )

                CSSecureField(
                    title: "Confirmar contraseña",
                    text: $confirmation,
                    placeholder: "Repite tu contraseña",
                    errorMessage: "Ejemplo de mensaje de error."
                )

                CSSecureField(
                    title: "No disponible",
                    text: $disabledPassword,
                    placeholder: "Campo deshabilitado"
                )
                .disabled(true)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground)
    }
}

#Preview("Claro") {
    CSSecureFieldPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    CSSecureFieldPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    CSSecureFieldPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
