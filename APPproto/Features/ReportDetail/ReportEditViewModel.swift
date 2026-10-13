//
//  ReportEditViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReportEditViewModel {
    var draft: ReportEditDraft

    private(set) var platforms: [Platform] = []
    private(set) var categories: [Category] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var isNoLongerEditable = false

    @ObservationIgnored
    private let original: Report

    @ObservationIgnored
    private let api: any APIClient

    init(report: Report, api: any APIClient) {
        original = report
        draft = ReportEditDraft(report: report)
        self.api = api
    }

    var selectedPlatformIsOther: Bool {
        platforms.first {
            $0.id == draft.platformID
        }?.esOtra == true
    }

    var canSave: Bool {
        guard original.esMio,
              original.estado == .pending,
              hasLoaded,
              !isLoading,
              !isSaving,
              !isNoLongerEditable else {
            return false
        }

        let title = trimmed(draft.title)
        let description = trimmed(draft.description)
        let otherPlatform = trimmed(draft.otherPlatform)

        guard !title.isEmpty,
              draft.title.count <= 150,
              description.count >= 20,
              draft.description.count <= 5000,
              draft.publicationURL.count <= 2048,
              validPublicationURL(trimmed(draft.publicationURL)),
              platforms.contains(where: {
                  $0.id == draft.platformID
              }),
              categories.contains(where: {
                  $0.id == draft.categoryID
              }) else {
            return false
        }

        if selectedPlatformIsOther {
            guard !otherPlatform.isEmpty,
                  draft.otherPlatform.count <= 100 else {
                return false
            }
        }

        return !changedFields.isEmpty
    }

    func loadCatalogs() async {
        guard !isLoading, !hasLoaded, !Task.isCancelled else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            async let fetchedPlatforms: [Platform] = api.send(
                Endpoint(path: "platforms"),
                expecting: [Platform].self
            )

            async let fetchedCategories: [Category] = api.send(
                Endpoint(path: "categories"),
                expecting: [Category].self
            )

            let result = try await (
                fetchedPlatforms,
                fetchedCategories
            )

            try Task.checkCancellation()

            platforms = result.0
            categories = result.1
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = message(
                for: error,
                fallback: "No se pudieron cargar las opciones del formulario. Intenta de nuevo."
            )
        }
    }

    func save() async -> Report? {
        guard canSave, !Task.isCancelled else {
            return nil
        }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            let body = try JSONSerialization.data(
                withJSONObject: changedFields
            )

            let report: Report = try await api.send(
                Endpoint(
                    path: "reports/\(original.id)",
                    method: .patch,
                    body: body
                ),
                expecting: Report.self
            )

            try Task.checkCancellation()

            guard report.id == original.id else {
                throw APIError.decoding
            }

            return report
        } catch is CancellationError {
            return nil
        } catch {
            if let apiError = error as? APIError,
               case .validation(let code) = apiError,
               code == "REPORT_NOT_EDITABLE" {
                isNoLongerEditable = true
                errorMessage =
                    "Este reporte ya fue revisado y no se puede modificar."
            } else {
                errorMessage = message(
                    for: error,
                    fallback: "No se pudieron guardar los cambios. Intenta de nuevo."
                )
            }

            return nil
        }
    }

    private var changedFields: [String: Any] {
        var fields: [String: Any] = [:]

        let title = trimmed(draft.title)
        let description = trimmed(draft.description)
        let publicationURL = trimmed(draft.publicationURL)

        if title != original.titulo {
            fields["titulo"] = title
        }

        if description != original.descripcion {
            fields["descripcion"] = description
        }

        if publicationURL != original.urlPublicacion {
            fields["urlPublicacion"] = publicationURL
        }

        if draft.platformID != original.plataforma.id {
            fields["plataformaId"] = draft.platformID
        }

        let otherPlatform: String? = selectedPlatformIsOther
            ? trimmed(draft.otherPlatform)
            : nil

        if otherPlatform != original.plataformaOtra {
            if let otherPlatform {
                fields["plataformaOtra"] = otherPlatform
            } else {
                fields["plataformaOtra"] = NSNull()
            }
        }

        if draft.categoryID != original.categoria.id {
            fields["categoriaId"] = draft.categoryID
        }

        if draft.isAnonymous != original.anonimo {
            fields["anonimo"] = draft.isAnonymous
        }

        return fields
    }

    private func validPublicationURL(_ value: String) -> Bool {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host,
              !host.isEmpty,
              components.user == nil,
              components.password == nil,
              components.url != nil else {
            return false
        }

        return true
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func message(
        for error: Error,
        fallback: String
    ) -> String {
        guard let apiError = error as? APIError else {
            return fallback
        }

        switch apiError {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para modificar este reporte."

        case .notFound:
            return "Este reporte ya no está disponible."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return fallback
        }
    }
}
