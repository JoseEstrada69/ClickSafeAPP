//
//  ReportSearchScreen.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import SwiftUI

@MainActor
struct ReportSearchScreen: View {
    private enum SelectionSheet: String, Identifiable {
        case platform
        case category

        var id: String { rawValue }
    }


    private let api: any APIClient
    private let focusRequest: UUID?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var model: ReportSearchViewModel
    @State private var path: [ReportSearchRoute] = []
    @State private var selectionSheet: SelectionSheet?
    @State private var catalogSearch = ""
    @State private var retryRequested = false

    init(
        api: any APIClient,
        focusRequest: UUID? = nil
    ) {
        self.api = api
        self.focusRequest = focusRequest

        _model = State(
            initialValue: ReportSearchViewModel(api: api)
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            searchForm
                .navigationTitle(
                    Text(verbatim: "Buscar reportes")
                )
                .navigationDestination(
                    for: ReportSearchRoute.self
                ) { route in
                    switch route {
                    case .results(let query):
                        ReportSearchResultsScreen(
                            query: query,
                            api: api
                        )

                    case .reportDetail(let id):
                        ReportDetailScreen(
                            reportID: id,
                            api: api
                        )
                    }
                }
        }
        .tint(Color.csNavy)
        .onChange(of: focusRequest) {
            guard focusRequest != nil else { return }

            selectionSheet = nil
            path.removeAll()
        }
    }

    private var searchForm: some View {
        @Bindable var model = model

        return ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.betweenBlocks
            ) {
                CSTextField(
                    title: "Enlace o palabra clave",
                    text: $model.query.text,
                    placeholder:
                        "Pega el enlace o escribe una palabra clave…",
                    focusRequest: focusRequest
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    search()
                }

                Text(
                    verbatim: "\(model.query.text.count)/100"
                )
                .font(.footnote)
                .foregroundStyle(
                    model.query.text.count > 100
                        ? Color.csDanger
                        : Color.csTextSecondary
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .trailing
                )

                PasteButton(payloadType: String.self) { values in
                    if let value = values.first {
                        model.query.text = value
                    }
                }
                .tint(Color.csNavy)

                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(
                            Text(verbatim: "Cargando filtros")
                        )
                }

                if model.hasLoaded {
                    CSCard {
                        VStack(
                            spacing: Theme.Spacing.withinCard
                        ) {
                            ChevronRow(
                                title: "Plataforma",
                                value: model.platformName
                            ) {
                                catalogSearch = ""
                                selectionSheet = .platform
                            }

                            ChevronRow(
                                title: "Tipo de fraude",
                                value: model.categoryName
                            ) {
                                catalogSearch = ""
                                selectionSheet = .category
                            }
                        }
                    }

                    VStack(
                        alignment: .leading,
                        spacing: Theme.Spacing.withinCard
                    ) {
                        Text(verbatim: "Estado")
                            .font(.subheadline)
                            .foregroundStyle(Color.csTextPrimary)

                        statusPicker
                    }

                    Picker(selection: $model.query.order) {
                        ForEach(
                            ReportSearchQuery.SortOrder.allCases
                        ) { order in
                            Text(verbatim: order.title)
                                .tag(order)
                        }
                    } label: {
                        Text(verbatim: "Orden")
                    }
                    .pickerStyle(.menu)
                    .frame(
                        minHeight: Theme.Size.minimumTouchTarget
                    )
                }

                if let message = model.errorMessage {
                    ErrorBanner(message: message) {
                        retryRequested = true
                    }
                    .disabled(
                        model.isLoading || retryRequested
                    )
                }

                PrimaryButton(title: "Buscar") {
                    search()
                }
                .disabled(!model.canSearch)
            }
            .padding(Theme.Spacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.csBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Text(
                verbatim:
                    "La ausencia de reportes no garantiza que una persona o publicación sea legítima."
            )
            .font(.footnote)
            .italic()
            .foregroundStyle(Color.csTextSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.screenMargin)
            .background(Color.csBackground)
        }
        .task {
            await model.loadCatalogs()
        }
        .task(id: retryRequested) {
            guard retryRequested else { return }

            await model.loadCatalogs()

            guard !Task.isCancelled else { return }
            retryRequested = false
        }
        .sheet(item: $selectionSheet) { sheet in
            switch sheet {
            case .platform:
                platformSelection
            case .category:
                categorySelection
            }
        }
        .onDisappear {
            retryRequested = false
        }
    }

    private var statusPicker: some View {
        @Bindable var model = model

        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                Picker(
                    selection: $model.query.status
                ) {
                    statusOptions
                } label: {
                    Text(verbatim: "Estado")
                }
                .pickerStyle(.menu)
                .frame(
                    minHeight: Theme.Size.minimumTouchTarget
                )
            } else {
                Picker(
                    selection: $model.query.status
                ) {
                    statusOptions
                } label: {
                    Text(verbatim: "Estado")
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var statusOptions: some View {
        ForEach(
            ReportSearchQuery.StatusFilter.allCases
        ) { status in
            Text(verbatim: status.title)
                .tag(status)
        }
    }

    private var platformSelection: some View {
        NavigationStack {
            List {
                Button {
                    model.query.platformID = nil
                    selectionSheet = nil
                } label: {
                    selectionRow(
                        title: "Todas",
                        selected: model.query.platformID == nil
                    )
                }

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
                        model.query.platformID = platform.id
                        selectionSheet = nil
                    } label: {
                        selectionRow(
                            title: platform.nombre,
                            selected:
                                model.query.platformID == platform.id
                        )
                    }
                }
            }
            .searchable(
                text: $catalogSearch,
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
                Button {
                    model.query.categoryID = nil
                    selectionSheet = nil
                } label: {
                    selectionRow(
                        title: "Todas",
                        selected: model.query.categoryID == nil
                    )
                }

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
                        model.query.categoryID = category.id
                        selectionSheet = nil
                    } label: {
                        selectionRow(
                            title: category.nombre,
                            selected:
                                model.query.categoryID == category.id
                        )
                    }
                }
            }
            .searchable(
                text: $catalogSearch,
                prompt: Text(verbatim: "Buscar tipo de fraude")
            )
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

    private func selectionRow(
        title: String,
        selected: Bool
    ) -> some View {
        HStack {
            Text(verbatim: title)
                .foregroundStyle(Color.csTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if selected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.csNavy)
                    .accessibilityLabel(
                        Text(verbatim: "Seleccionada")
                    )
            }
        }
        .frame(minHeight: Theme.Size.minimumTouchTarget)
        .contentShape(Rectangle())
    }

    private func search() {
        guard model.canSearch else { return }
        path.append(.results(model.query))
    }
}
