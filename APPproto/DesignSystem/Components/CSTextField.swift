//
//  CSTextField.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 05/10/26.
//

import SwiftUI

struct CSTextField: View {
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var isFocused: Bool

    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var errorMessage: String? = nil
    var focusRequest: UUID? = nil

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

            TextField(
                title,
                text: $text,
                prompt: Text(verbatim: placeholder)
                    .foregroundStyle(Color.csTextSecondary)
            )
            .textFieldStyle(.plain)
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
            .task(id: focusRequest) {
                guard focusRequest != nil, isEnabled else {
                    return
                }

                do {
                    try await Task.sleep(
                        for: .milliseconds(200)
                    )

                    try Task.checkCancellation()

                    guard isEnabled else { return }
                    isFocused = true
                } catch is CancellationError {
                    return
                } catch {
                    return
                }
            }

            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.csDanger)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
        .opacity(isEnabled ? 1 : Theme.disabledOpacity)
    }
}

private struct CSTextFieldPreview: View {
    @State private var name = ""
    @State private var reportTitle = ""
    @State private var disabledText = "Campo deshabilitado"

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.betweenBlocks) {
                CSTextField(
                    title: "Nombre",
                    text: $name,
                    placeholder: "Escribe tu nombre"
                )

                CSTextField(
                    title: "Título del reporte",
                    text: $reportTitle,
                    placeholder: "Describe el caso brevemente",
                    errorMessage: "Ejemplo de mensaje de error."
                )

                CSTextField(
                    title: "No disponible",
                    text: $disabledText
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
    CSTextFieldPreview()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    CSTextFieldPreview()
        .preferredColorScheme(.dark)
}

#Preview("Texto grande") {
    CSTextFieldPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
