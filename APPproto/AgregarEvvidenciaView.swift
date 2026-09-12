////  AgregarEvidenciaView.swift
//  ClickSafe
//
//  Pantalla 2 de 3 del flujo "Reportar posible fraude" (slide 9 del mockup).
//

import SwiftUI

struct AgregarEvidenciaView: View {

    @ObservedObject var draft: ReporteDraft

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            Color.csBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: CSMetrics.sectionSpacing) {

                    Text("Agregar evidencia")
                        .csTitle()
                        .padding(.top, 8)

                    Text("Adjunta capturas, fotos o comprobantes que respalden tu reporte.")
                        .font(.system(size: 14))
                        .foregroundColor(.csTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Selector de archivos
                    Button("Seleccionar fotografías o archivos") {
                        agregarArchivoDePrueba()
                    }
                    .buttonStyle(CSAccentButtonStyle())

                    // Lista de adjuntos
                    if !draft.evidencias.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(draft.evidencias, id: \.self) { archivo in
                                HStack(spacing: 8) {
                                    Image(systemName: "paperclip")
                                        .font(.system(size: 13))
                                        .foregroundColor(.csAccent)

                                    Text(archivo)
                                        .font(.system(size: 13))
                                        .foregroundColor(.csTextSecondary)

                                    Spacer()

                                    Button {
                                        quitarArchivo(archivo)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.csTextSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.leading, 4)
                    }

                    // Resumen del reporte
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Resumen del reporte")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.csNavy)

                        VStack(alignment: .leading, spacing: 6) {
                            filaResumen(etiqueta: "Plataforma", valor: draft.plataforma)
                            filaResumen(etiqueta: "Categoría", valor: draft.tipoFraude)
                            filaResumen(etiqueta: "Publicación anónima", valor: draft.textoAnonimato)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .csSurface()
                    .padding(.top, 8)

                    // Acciones
                    VStack(spacing: 12) {
                        Button("Enviar reporte") {
                            // Siguiente pantalla: ReporteEnviadoView
                        }
                        .buttonStyle(CSPrimaryButtonStyle())

                        Button("Volver") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(CSSecondaryButtonStyle())
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, CSMetrics.screenPadding)
                .padding(.vertical, 24)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Subvistas

    private func filaResumen(etiqueta: String, valor: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(etiqueta):")
                .font(.system(size: 13))
                .foregroundColor(.csTextSecondary)

            Text(valor.isEmpty ? "—" : valor)
                .font(.system(size: 13))
                .foregroundColor(.csTextPrimary)
        }
    }

    // MARK: - Acciones provisionales

    /// Simula la selección de un archivo mientras conectamos el picker real.
    private func agregarArchivoDePrueba() {
        let nombres = ["captura_chat.png", "comprobante.jpg", "conversacion.png"]
        if let siguiente = nombres.first(where: { !draft.evidencias.contains($0) }) {
            draft.evidencias.append(siguiente)
        }
    }

    private func quitarArchivo(_ archivo: String) {
        draft.evidencias.removeAll { $0 == archivo }
    }
}

// MARK: - Preview

struct AgregarEvidenciaView_Previews: PreviewProvider {
    static var previews: some View {
        let draft = ReporteDraft()
        draft.plataforma = "Mercado Libre"
        draft.tipoFraude = "Producto no enviado"
        draft.evidencias = ["captura_chat.png", "comprobante.jpg"]

        return AgregarEvidenciaView(draft: draft)
    }
}
