import SwiftUI

struct CrearReporteView: View {

    // Borrador compartido con el resto del flujo.
    @StateObject private var draft = ReporteDraft()

    // Controla el paso a la pantalla de evidencia.
    @State private var irAEvidencia = false

    // Opciones provisionales. Cuando el backend esté conectado, vienen del endpoint
    // de Plataforma y Categoria_fraude en lugar de estar aquí.
    private let plataformas = ["Mercado Libre", "Facebook Marketplace", "Otra"]
    private let tiposDeFraude = [
        "Vendedor falso o suplantación",
        "Producto nunca enviado",
        "Producto distinto al anunciado",
        "Pago solicitado fuera de la plataforma"
    ]

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                Color.csBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: CSMetrics.sectionSpacing) {

                        Text("Reportar posible fraude")
                            .csTitle()
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        campoDeTexto(
                            etiqueta: "Título del reporte",
                            texto: $draft.titulo
                        )

                        selector(
                            etiqueta: "Plataforma",
                            seleccion: $draft.plataforma,
                            opciones: plataformas
                        )

                        selector(
                            etiqueta: "Tipo de fraude",
                            seleccion: $draft.tipoFraude,
                            opciones: tiposDeFraude
                        )

                        // Descripción
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Descripción").csFieldLabel()

                            ZStack(alignment: .topLeading) {
                                if draft.descripcion.isEmpty {
                                    Text("Describe qué pasó, cuándo y cómo ocurrió el posible fraude...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.csTextSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }

                                TextEditor(text: $draft.descripcion)
                                    .font(.system(size: 14))
                                    .foregroundColor(.csTextPrimary)
                                    .scrollContentBackground(.hidden)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .frame(height: 120)
                            .csSurface()
                        }

                        // Publicar de forma anónima
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: $draft.esAnonimo) {
                                Text("Publicar de forma anónima")
                                    .font(.system(size: 14))
                                    .foregroundColor(.csTextPrimary)
                            }
                            .tint(.csNavy)

                            Text("El anonimato oculta tu identidad públicamente en el reporte.")
                                .csCaption()
                        }
                        .padding(.top, 4)

                        // Continuar
                        Button("Continuar") {
                            irAEvidencia = true
                        }
                        .buttonStyle(CSPrimaryButtonStyle())
                        .disabled(!draft.datosBasicosCompletos)
                        .opacity(draft.datosBasicosCompletos ? 1 : 0.5)
                        .padding(.top, 12)

                        // Enlace invisible que dispara la navegación.
                        NavigationLink(
                            destination: AgregarEvidenciaView(draft: draft),
                            isActive: $irAEvidencia
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    }
                    .padding(.horizontal, CSMetrics.screenPadding)
                    .padding(.vertical, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Subvistas

    /// Etiqueta pequeña + campo de texto blanco con borde.
    private func campoDeTexto(etiqueta: String, texto: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(etiqueta).csFieldLabel()

            TextField("", text: texto)
                .font(.system(size: 15))
                .foregroundColor(.csTextPrimary)
                .padding(.horizontal, 14)
                .frame(height: CSMetrics.fieldHeight)
                .csSurface()
        }
    }

    /// Fila tipo tarjeta con chevron que despliega las opciones.
    private func selector(
        etiqueta: String,
        seleccion: Binding<String>,
        opciones: [String]
    ) -> some View {
        Menu {
            ForEach(opciones, id: \.self) { opcion in
                Button(opcion) { seleccion.wrappedValue = opcion }
            }
        } label: {
            HStack {
                Text(seleccion.wrappedValue.isEmpty ? etiqueta : seleccion.wrappedValue)
                    .font(.system(size: 15))
                    .foregroundColor(seleccion.wrappedValue.isEmpty ? .csTextPrimary : .csNavy)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csTextSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: CSMetrics.fieldHeight)
            .csSurface()
        }
    }
}

// MARK: - Preview

struct CrearReporteView_Previews: PreviewProvider {
    static var previews: some View {
        CrearReporteView()
    }
}
