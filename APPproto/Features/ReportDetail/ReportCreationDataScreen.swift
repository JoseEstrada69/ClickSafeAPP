//
//  ReportCreationDataScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct ReportCreationDataScreen: View {
    private enum SelectionSheet: String, Identifiable {
        case platform
        case category

        var id: String { rawValue }
    }

    @Bindable var model: ReportCreationViewModel
    let onContinue: () -> Void

    @State private var selectionSheet: SelectionSheet?
    @State private var catalogSearch = ""
    @State private var retryRequested = false

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                Text(verbatim: "Paso 1 de 2")
                    .font(.subheadline)
                    .foregroundStyle(Color.csTextSecondary)

                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Cargando formulario")
                }

                if model.hasLoaded {
                    fields

                    PrimaryButton(title: "Continuar") {
                        guard model.canContinue else {
                            return
                        }

                        onContinue()
                    }
                    .disabled(!model.canContinue)
                }

                if let message = model.errorMessage {
                    ErrorBanner(message: message) {
                        retryRequested = true
                    }
                    .disabled(model.isBusy || retryRequested)
                }
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(
            Text(verbatim: "Reportar posible fraude")
        )
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.loadCatalogs()
        }
        .task(id: retryRequested) {
            guard retryRequested else {
                return
            }

            await model.loadCatalogs()

            guard !Task.isCancelled else {
                return
            }

            retryRequested = false
        }
        .sheet(item: $selectionSheet) { sheet in
            catalogSelection(sheet)
        }
        .onDisappear {
            retryRequested = false
        }
    }

    private var fields: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.betweenBlocks
        ) {
            CSTextField(
                title: "Enlace de la publicación",
                text: $model.draft.publicationURL,
                placeholder: "https://..."
            )
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            characterCounter(
                model.draft.publicationURL.count,
                maximum: 2048
            )

            PasteButton(payloadType: String.self) { values in
                if let value = values.first {
                    model.draft.publicationURL = value
                }
            }
            .tint(Color.csNavy)

            CSTextField(
                title: "Título del reporte",
                text: $model.draft.title,
                placeholder: "Describe el caso brevemente"
            )

            characterCounter(
                model.draft.title.count,
                maximum: 150
            )

            CSCard {
                VStack(spacing: Theme.Spacing.withinCard) {
                    ChevronRow(
                        title: "Plataforma",
                        value: model.selectedPlatform?.nombre
                            ?? "Seleccionar"
                    ) {
                        catalogSearch = ""
                        selectionSheet = .platform
                    }

                    ChevronRow(
                        title: "Tipo de fraude",
                        value: model.selectedCategory?.nombre
                            ?? "Seleccionar"
                    ) {
                        catalogSearch = ""
                        selectionSheet = .category
                    }
                }
            }

            if model.selectedPlatformIsOther {
                CSTextField(
                    title: "Nombre de la tienda",
                    text: $model.draft.otherPlatform,
                    placeholder: "Escribe el nombre"
                )

                characterCounter(
                    model.draft.otherPlatform.count,
                    maximum: 100
                )
            }

            descriptionField

            Toggle(isOn: $model.draft.isAnonymous) {
                Text(verbatim: "Publicar de forma anónima")
                    .foregroundStyle(Color.csTextPrimary)
            }
            .tint(Color.csGold)

            Text(
                verbatim:
                    "Tu nombre no se mostrará a otros usuarios. Los administradores de ClickSafe sí pueden ver quién hizo el reporte."
            )
            .font(.footnote)
            .foregroundStyle(Color.csTextSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .disabled(model.isBusy)
    }

    private var descriptionField: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.withinCard
        ) {
            Text(verbatim: "Descripción")
                .font(.subheadline)
                .foregroundStyle(Color.csTextPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.draft.description)
                    .font(.body)
                    .foregroundStyle(Color.csTextPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 160)
                    .accessibilityLabel("Descripción")

                if model.draft.description.isEmpty {
                    Text(
                        verbatim:
                            "Describe qué pasó, cuándo y cómo ocurrió el posible fraude…"
                    )
                    .font(.body)
                    .foregroundStyle(Color.csTextSecondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .padding(Theme.Spacing.withinCard)
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
                    Color.csBorder,
                    lineWidth: Theme.BorderWidth.standard
                )
            }

            characterCounter(
                model.draft.description.count,
                maximum: 5000
            )

            Text(verbatim: "Mínimo 20 caracteres.")
                .font(.footnote)
                .foregroundStyle(Color.csTextSecondary)
        }
    }

    private func catalogSelection(
        _ sheet: SelectionSheet
    ) -> some View {
        NavigationStack {
            List {
                switch sheet {
                case .platform:
                    ForEach(
                        model.platforms.filter {
                            catalogSearch.isEmpty
                                || $0.nombre.localizedCaseInsensitiveContains(
                                    catalogSearch
                                )
                        },
                        id: \.id
                    ) { platform in
                        Button {
                            model.draft.platformID = platform.id
                            selectionSheet = nil
                        } label: {
                            selectionRow(
                                title: platform.nombre,
                                description: nil,
                                selected:
                                    model.draft.platformID == platform.id
                            )
                        }
                    }

                case .category:
                    ForEach(
                        model.categories.filter {
                            catalogSearch.isEmpty
                                || $0.nombre.localizedCaseInsensitiveContains(
                                    catalogSearch
                                )
                        },
                        id: \.id
                    ) { category in
                        Button {
                            model.draft.categoryID = category.id
                            selectionSheet = nil
                        } label: {
                            selectionRow(
                                title: category.nombre,
                                description: category.descripcion,
                                selected:
                                    model.draft.categoryID == category.id
                            )
                        }
                    }
                }
            }
            .searchable(
                text: $catalogSearch,
                prompt: Text(
                    verbatim: sheet == .platform
                        ? "Buscar plataforma"
                        : "Buscar tipo de fraude"
                )
            )
            .navigationTitle(
                Text(
                    verbatim: sheet == .platform
                        ? "Plataforma"
                        : "Tipo de fraude"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        selectionSheet = nil
                    }
                }
            }
        }
        .tint(Color.csNavy)
    }

    private func selectionRow(
        title: String,
        description: String?,
        selected: Bool
    ) -> some View {
        HStack(alignment: .top) {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.withinCard
            ) {
                Text(verbatim: title)
                    .font(.headline)
                    .foregroundStyle(Color.csTextPrimary)

                if let description, !description.isEmpty {
                    Text(verbatim: description)
                        .font(.body)
                        .foregroundStyle(Color.csTextSecondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if selected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.csNavy)
                    .accessibilityLabel("Seleccionada")
            }
        }
        .frame(minHeight: Theme.Size.minimumTouchTarget)
        .contentShape(Rectangle())
    }

    private func characterCounter(
        _ count: Int,
        maximum: Int
    ) -> some View {
        Text(verbatim: "\(count)/\(maximum)")
            .font(.footnote)
            .foregroundStyle(
                count > maximum
                    ? Color.csDanger
                    : Color.csTextSecondary
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
