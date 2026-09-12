//
//  theme.swift
//  APPproto
//
//  Created by alumno on 11/09/26.
//
//  Theme.swift
//  ClickSafe
//
//  Paleta de color y estilos compartidos por todas las pantallas.
//  No es una View: es solo código de apoyo para mantener consistencia visual.
//

import SwiftUI

// MARK: - Paleta

extension Color {
    /// Azul marino de marca. Botones primarios, títulos, header.
    static let csNavy = Color(hex: "13304F")
    /// Fondo crema de las pantallas.
    static let csBackground = Color(hex: "F2F0EA")
    /// Fondo de tarjetas y campos de texto.
    static let csSurface = Color.white
    /// Borde hairline de tarjetas e inputs.
    static let csBorder = Color(hex: "E3E0D8")
    /// Texto de cuerpo.
    static let csTextPrimary = Color(hex: "1A1A1A")
    /// Etiquetas, metadatos y notas.
    static let csTextSecondary = Color(hex: "6E6E6E")
    /// Acento dorado: estados pendientes y acciones secundarias destacadas.
    static let csAccent = Color(hex: "C69A43")

    /// Inicializa un color a partir de un hex tipo "13304F" o "#13304F".
    init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Medidas

enum CSMetrics {
    static let cornerRadius: CGFloat = 10
    static let fieldHeight: CGFloat = 46
    static let screenPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 18
}

// MARK: - Estilos de botón

/// Botón sólido azul marino a todo el ancho. Acción principal de cada pantalla.
struct CSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: CSMetrics.fieldHeight)
            .background(Color.csNavy)
            .clipShape(RoundedRectangle(cornerRadius: CSMetrics.cornerRadius))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Botón con contorno marino y fondo transparente. Acciones secundarias ("Volver").
struct CSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.csNavy)
            .frame(maxWidth: .infinity)
            .frame(height: CSMetrics.fieldHeight)
            .background(Color.csSurface)
            .overlay(
                RoundedRectangle(cornerRadius: CSMetrics.cornerRadius)
                    .stroke(Color.csNavy, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CSMetrics.cornerRadius))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Modificadores

/// Fondo blanco + borde + esquinas redondeadas: el look de tarjetas e inputs.
struct CSSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.csSurface)
            .clipShape(RoundedRectangle(cornerRadius: CSMetrics.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CSMetrics.cornerRadius)
                    .stroke(Color.csBorder, lineWidth: 1)
            )
    }
}

extension View {
    func csSurface() -> some View {
        modifier(CSSurfaceModifier())
    }
}

// MARK: - Tipografía

extension Text {
    /// Título grande de pantalla.
    func csTitle() -> some View {
        self.font(.system(size: 24, weight: .bold))
            .foregroundColor(.csNavy)
    }

    /// Etiqueta pequeña encima de un campo.
    func csFieldLabel() -> some View {
        self.font(.system(size: 13, weight: .regular))
            .foregroundColor(.csTextSecondary)
    }

    /// Nota o advertencia al pie.
    func csCaption() -> some View {
        self.font(.system(size: 12))
            .foregroundColor(.csTextSecondary)
    }
}

