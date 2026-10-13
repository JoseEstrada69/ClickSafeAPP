//
//  ReportEditScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct ReportEditScreen: View {
    private enum SelectionSheet: String, Identifiable {
        case platform
        case category

        var id: String { rawValue }
    }

    let onSaved: (Report) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var model: ReportEditViewModel
    @State private var evidenceModel: ReportEvidenceEditViewModel
    @State private var selectionSheet: SelectionSheet?
    @State private var platformSearch = ""
    @State private var saveRequested = false
    @State private var retryRequested = false
    @State private var isUpdatingDetail = false
    @State private var showsNotEditable = false

    init(
        report: Report,
        api: any APIClient,
        onSaved: @escaping (Report) async -> Void
    ) {
        self.onSaved = onSaved

        _model = State(
            initialValue: ReportEditViewModel(
                report: report,
                api: api
            )
        )

        _evidenceModel = State(
            initialValue: ReportEvidenceEditViewModel(
                report: report,
                api: api
            )
        )
    }

    private var isSavingFields: Bool {
        model.isSaving || saveRequested
    }

    private var isBusy: Bool {
        isSavingFields
            || evidenceModel.isBusy
            || isUpdatingDetail
    }

    private var isNoLongerEditable: Bool {
        model.isNoLongerEditable
            || evidenceModel.isNoLongerEditable
    }

    private var canSaveFields: Bool {
        model.canSave
            && !isBusy
            && !isNoLongerEditable
            && evidenceModel.pendingImages.isEmpty
    }

    private var platformName: String {
        model.platforms.first {
            $0.id == model.draft.platformID
        }?.nombre ?? "Seleccionar"
    }

    private var categoryName: String {
        model.categories.first {
            $0.id == model.draft.categoryID
        }?.nombre ?? "Seleccionar"
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(
                            Text(verbatim: "Cargando formulario")
                        )
                }

                if model.hasLoaded {
                    reportFields
                        .disabled(isBusy || isNoLongerEditable)

                    ReportEvidenceEditView(
                        model: evidenceModel,
                        onChanged: {
                            isUpdatingDetail = true

                            await onSaved(
                                evidenceModel.currentReport
                            )

                            isUpdatingDetail = false
                        }
                    )
                    .disabled(
                        isSavingFields
                            || isUpdatingDetail
                            || isNoLongerEditable
                    )

                    if !evidenceModel.pendingImages.isEmpty {
                        Text(
                            verbatim:
                                "Sube las imágenes seleccionadas o quítalas antes de guardar los cambios del formulario."
                        )
                        .font(.footnote)
                        .foregroundStyle(Color.csTextSecondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                    }
                }

                if let message = model.errorMessage,
                   !isNoLongerEditable {
                    ErrorBanner(message: message) {
                        if model.hasLoaded {
                            saveRequested = true
                        } else {
                            retryRequested = true
                        }
                    }
                    .disabled(
                        isBusy
                            || model.isLoading
                            || retryRequested
                            || (model.hasLoaded && !canSaveFields)
                    )
                }

                if model.hasLoaded {
                    PrimaryButton(
                        title: isSavingFields
                            ? "Guardando…"
                            : "Guardar cambios"
                    ) {
                        saveRequested = true
                    }
                    .disabled(!canSaveFields)
                }

                if isSavingFields || isUpdatingDetail {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(
                            Text(
                                verbatim: isSavingFields
                                    ? "Guardando cambios"
                                    : "Actualizando detalle"
                            )
                        )
                }
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Editar reporte"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isBusy)
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
        .task(id: saveRequested) {
            guard saveRequested else {
                return
            }

            guard !evidenceModel.isBusy,
                  !isUpdatingDetail,
                  !isNoLongerEditable,
                  evidenceModel.pendingImages.isEmpty else {
                saveRequested = false
                return
            }

            if let report = await model.save() {
                guard !Task.isCancelled else {
                    return
                }

                await onSaved(report)

                guard !Task.isCancelled else {
                    return
                }

                saveRequested = false
                dismiss()
            } else {
                guard !Task.isCancelled else {
                    return
                }

                saveRequested = false
                showsNotEditable = isNoLongerEditable
            }
        }
        .onChange(of: evidenceModel.isNoLongerEditable) {
            _, noLongerEditable in

            if noLongerEditable {
                showsNotEditable = true
            }
        }
        .sheet(item: $selectionSheet) { sheet in
            switch sheet {
            case .platform:
                platformSelection

            case .category:
                categorySelection
            }
        }
        .alert(
            Text(verbatim: "Reporte revisado"),
            isPresented: $showsNotEditable
        ) {
            Button {
                dismiss()
            } label: {
                Text(verbatim: "Volver al detalle")
            }
        } message: {
            Text(
                verbatim:
                    "Este reporte ya fue revisado y no se puede modificar."
            )
        }
        .onDisappear {
            saveRequested = false
            retryRequested = false
        }
    }

    private var reportFields: some View {
        @Bindable var model = model

        return VStack(
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
                        value: platformName
                    ) {
                        platformSearch = ""
                        selectionSheet = .platform
                    }

                    ChevronRow(
                        title: "Tipo de fraude",
                        value: categoryName
                    ) {
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
    }

    private var descriptionField: some View {
        @Bindable var model = model

        return VStack(
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
                    .accessibilityLabel(
                        Text(verbatim: "Descripción")
                    )

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

    private var platformSelection: some View {
        NavigationStack {
            List {
                ForEach(
                    model.platforms.filter {
                        platformSearch.isEmpty
                            || $0.nombre.localizedCaseInsensitiveContains(
                                platformSearch
                            )
                    },
                    id: \.id
                ) { platform in
                    Button {
                        model.draft.platformID = platform.id
                        selectionSheet = nil
                    } label: {
                        HStack {
                            Text(verbatim: platform.nombre)
                                .foregroundStyle(Color.csTextPrimary)

                            Spacer()

                            if model.draft.platformID == platform.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.csNavy)
                                    .accessibilityLabel(
                                        Text(verbatim: "Seleccionada")
                                    )
                            }
                        }
                        .frame(
                            minHeight: Theme.Size.minimumTouchTarget
                        )
                    }
                }
            }
            .searchable(
                text: $platformSearch,
                prompt: Text(verbatim: "Buscar plataforma")
            )
            .navigationTitle(Text(verbatim: "Plataforma"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        selectionSheet = nil
                    } label: {
                        Text(verbatim: "Cancelar")
                    }
                }
            }
        }
        .tint(Color.csNavy)
    }

    private var categorySelection: some View {
        NavigationStack {
            List {
                ForEach(model.categories, id: \.id) { category in
                    Button {
                        model.draft.categoryID = category.id
                        selectionSheet = nil
                    } label: {
                        HStack(alignment: .top) {
                            VStack(
                                alignment: .leading,
                                spacing: Theme.Spacing.withinCard
                            ) {
                                Text(verbatim: category.nombre)
                                    .font(.headline)
                                    .foregroundStyle(Color.csTextPrimary)

                                if let description = category.descripcion,
                                   !description.isEmpty {
                                    Text(verbatim: description)
                                        .font(.body)
                                        .foregroundStyle(
                                            Color.csTextSecondary
                                        )
                                }
                            }
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                            Spacer()

                            if model.draft.categoryID == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.csNavy)
                                    .accessibilityLabel(
                                        Text(verbatim: "Seleccionado")
                                    )
                            }
                        }
                        .frame(
                            minHeight: Theme.Size.minimumTouchTarget
                        )
                    }
                }
            }
            .navigationTitle(Text(verbatim: "Tipo de fraude"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        selectionSheet = nil
                    } label: {
                        Text(verbatim: "Cancelar")
                    }
                }
            }
        }
        .tint(Color.csNavy)
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
