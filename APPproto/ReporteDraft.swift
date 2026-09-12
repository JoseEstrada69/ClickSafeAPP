//
//  ReporteDraft.swift
//  ClickSafe
//
//  Borrador del reporte que se va llenando a lo largo del flujo.
//  Vive desde la pantalla de crear reporte hasta el envío.
//  No es una View: es el modelo que comparten las pantallas del flujo.
//

import SwiftUI

final class ReporteDraft: ObservableObject {
    @Published var titulo: String = ""
    @Published var plataforma: String = ""
    @Published var tipoFraude: String = ""
    @Published var descripcion: String = ""
    @Published var esAnonimo: Bool = false

    /// Nombres de los archivos adjuntos. Cuando conectemos el picker real,
    /// aquí habrá que guardar también los datos de cada imagen.
    @Published var evidencias: [String] = []

    /// Texto listo para mostrar en el resumen.
    var textoAnonimato: String {
        esAnonimo ? "Sí" : "No"
    }

    /// Campos obligatorios de la primera pantalla.
    var datosBasicosCompletos: Bool {
        !titulo.trimmingCharacters(in: .whitespaces).isEmpty
        && !plataforma.isEmpty
        && !tipoFraude.isEmpty
        && !descripcion.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
