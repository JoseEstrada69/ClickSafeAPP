//
//  ReportCreationViewModel.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class ReportCreationViewModel {
    var draft: ReportCreationDraft

    private(set) var platforms: [Platform] = []
    private(set) var categories: [Category] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var isProcessingImages = false
    private(set) var isSending = false
    private(set) var errorMessage: String?
    private(set) var submittedReport: Report?

    @ObservationIgnored
    private let api: any APIClient

    var isBusy: Bool {
        isLoading || isProcessingImages || isSending
    }

    var selectedPlatform: Platform? {
        platforms.first {
            $0.id == draft.platformID
        }
    }

    var selectedCategory: Category? {
        categories.first {
            $0.id == draft.categoryID
        }
    }

    var selectedPlatformIsOther: Bool {
        selectedPlatform?.esOtra == true
    }

    var remainingImageSlots: Int {
        max(0, 5 - draft.evidences.count)
    }

    var publicationDomain: String? {
        validPublicationURL?.host
    }

    var canContinue: Bool {
        guard hasLoaded,
              !isBusy,
              submittedReport == nil,
              validPublicationURL != nil,
              selectedPlatform != nil,
              selectedCategory != nil else {
            return false
        }

        let title = draft.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let description = draft.description.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !title.isEmpty,
              draft.title.count <= 150,
              description.count >= 20,
              draft.description.count <= 5000 else {
            return false
        }

        if selectedPlatformIsOther {
            let name = draft.otherPlatform.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !name.isEmpty,
                  draft.otherPlatform.count <= 100 else {
                return false
            }
        }

        return true
    }

    var canSubmit: Bool {
        canContinue && draft.evidences.count <= 5
    }

    private var validPublicationURL: URL? {
        let text = draft.publicationURL.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard draft.publicationURL.count <= 2048,
              let components = URLComponents(string: text),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host,
              !host.isEmpty,
              components.user == nil,
              components.password == nil,
              let url = components.url else {
            return nil
        }

        return url
    }

    init(
        api: any APIClient,
        publicationURL: String = ""
    ) {
        self.api = api
        draft = ReportCreationDraft(
            publicationURL: publicationURL
        )
    }

    func loadCatalogs() async {
        guard !isBusy,
              !hasLoaded,
              !Task.isCancelled else {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            async let loadedPlatforms: [Platform] = api.send(
                Endpoint(path: "platforms"),
                expecting: [Platform].self
            )

            async let loadedCategories: [Category] = api.send(
                Endpoint(path: "categories"),
                expecting: [Category].self
            )

            let (platforms, categories) = try await (
                loadedPlatforms,
                loadedCategories
            )

            try Task.checkCancellation()

            self.platforms = platforms
            self.categories = categories
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = message(for: error)
        }
    }

    func processImages(_ items: [PhotosPickerItem]) async {
        guard !isBusy,
              submittedReport == nil,
              !items.isEmpty,
              !Task.isCancelled else {
            return
        }

        guard items.count <= remainingImageSlots else {
            errorMessage = "Máximo 5 imágenes por reporte."
            return
        }

        isProcessingImages = true
        errorMessage = nil

        defer {
            isProcessingImages = false
        }

        do {
            var processed: [PendingEvidence] = []

            for item in items {
                try Task.checkCancellation()

                guard let data = try await item.loadTransferable(
                    type: Data.self
                ) else {
                    throw ImageSanitizationError.invalidImage
                }

                let jpeg = try ImageSanitizer.sanitize(data)

                processed.append(
                    PendingEvidence(jpegData: jpeg)
                )
            }

            try Task.checkCancellation()
            draft.evidences.append(contentsOf: processed)
        } catch is CancellationError {
            return
        } catch let error as ImageSanitizationError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage =
                "No se pudieron preparar las fotografías. Intenta con otras imágenes."
        }
    }

    func removeImage(id: UUID) {
        guard !isBusy, submittedReport == nil else {
            return
        }

        draft.evidences.removeAll {
            $0.id == id
        }
    }

    func submit() async -> Report? {
        guard canSubmit,
              let platform = selectedPlatform,
              let category = selectedCategory,
              !Task.isCancelled else {
            return nil
        }

        isSending = true
        errorMessage = nil

        defer {
            isSending = false
        }

        do {
            var multipart = MultipartFormData()

            try multipart.addField(
                name: "titulo",
                value: draft.title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )

            try multipart.addField(
                name: "descripcion",
                value: draft.description.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )

            try multipart.addField(
                name: "urlPublicacion",
                value: draft.publicationURL.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )

            try multipart.addField(
                name: "plataformaId",
                value: String(platform.id)
            )

            if platform.esOtra {
                try multipart.addField(
                    name: "plataformaOtra",
                    value: draft.otherPlatform.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                )
            }

            try multipart.addField(
                name: "categoriaId",
                value: String(category.id)
            )

            try multipart.addField(
                name: "anonimo",
                value: draft.isAnonymous ? "true" : "false"
            )

            for (index, evidence) in draft.evidences.enumerated() {
                try Task.checkCancellation()

                try multipart.addEvidence(
                    jpegData: evidence.jpegData,
                    number: index + 1
                )
            }

            try Task.checkCancellation()

            let report: Report = try await api.send(
                Endpoint(
                    path: "reports",
                    method: .post,
                    body: multipart.body,
                    contentType: multipart.contentType
                ),
                expecting: Report.self
            )

            try Task.checkCancellation()

            guard report.id > 0,
                  report.evidencias.count <= 5 else {
                throw APIError.decoding
            }

            submittedReport = report
            return report
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = message(for: error)
            return nil
        }
    }

    func reset(publicationURL: String = "") {
        guard !isBusy else {
            return
        }

        draft = ReportCreationDraft(
            publicationURL: publicationURL
        )
        submittedReport = nil
        errorMessage = nil
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "No se pudo completar la solicitud. Inténtalo de nuevo."
        }

        switch apiError {
        case .validation(let code):
            switch code {
            case "INVALID_IMAGE":
                return "Una de las imágenes no es válida. Quítala e intenta de nuevo."
            case "EVIDENCE_LIMIT":
                return "Máximo 5 imágenes por reporte."
            default:
                return "Revisa los datos del reporte e inténtalo de nuevo."
            }

        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            return "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            return "No tienes permiso para realizar esta acción."

        case .rateLimited:
            return "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            return "No se pudo completar la solicitud. Inténtalo de nuevo."
        }
    }
}
