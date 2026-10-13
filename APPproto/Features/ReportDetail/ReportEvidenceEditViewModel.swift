//
//  ReportEvidenceEditViewModel.swift
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
final class ReportEvidenceEditViewModel {
    private(set) var currentReport: Report
    private(set) var pendingImages: [PendingEvidence] = []
    private(set) var isProcessing = false
    private(set) var isUploading = false
    private(set) var isDeleting = false
    private(set) var errorMessage: String?
    private(set) var isNoLongerEditable = false

    @ObservationIgnored
    private let api: any APIClient

    var evidences: [Evidence] {
        currentReport.evidencias
    }

    var isBusy: Bool {
        isProcessing || isUploading || isDeleting
    }

    var remainingSlots: Int {
        max(0, 5 - evidences.count - pendingImages.count)
    }

    var totalImageCount: Int {
        evidences.count + pendingImages.count
    }

    private var canEditReport: Bool {
        currentReport.esMio
            && currentReport.estado == .pending
            && !isNoLongerEditable
    }

    var canUpload: Bool {
        canEditReport
            && !isBusy
            && !pendingImages.isEmpty
            && totalImageCount <= 5
    }

    init(report: Report, api: any APIClient) {
        currentReport = report
        self.api = api
    }

    func process(_ items: [PhotosPickerItem]) async {
        guard canEditReport,
              !isBusy,
              !items.isEmpty,
              !Task.isCancelled else {
            return
        }

        guard items.count <= remainingSlots else {
            errorMessage = "Máximo 5 imágenes por reporte."
            return
        }

        isProcessing = true
        errorMessage = nil

        defer {
            isProcessing = false
        }

        var processed: [PendingEvidence] = []

        do {
            for item in items {
                try Task.checkCancellation()

                guard let data = try await item.loadTransferable(
                    type: Data.self
                ) else {
                    throw ImageSanitizationError.invalidImage
                }

                let jpeg = try ImageSanitizer.sanitize(data)
                processed.append(PendingEvidence(jpegData: jpeg))
            }

            try Task.checkCancellation()
            pendingImages.append(contentsOf: processed)
        } catch is CancellationError {
            return
        } catch {
            errorMessage =
                "No se pudieron preparar las fotografías seleccionadas. Intenta con otras imágenes."
        }
    }

    func removePending(id: UUID) {
        guard !isBusy else {
            return
        }

        pendingImages.removeAll { $0.id == id }
    }

    func upload() async -> Report? {
        guard canUpload, !Task.isCancelled else {
            return nil
        }

        isUploading = true
        errorMessage = nil

        defer {
            isUploading = false
        }

        do {
            var multipart = MultipartFormData()

            for (index, image) in pendingImages.enumerated() {
                try multipart.addEvidence(
                    jpegData: image.jpegData,
                    number: index + 1
                )
            }

            let report: Report = try await api.send(
                Endpoint(
                    path: "reports/\(currentReport.id)/evidences",
                    method: .post,
                    body: multipart.body,
                    contentType: multipart.contentType
                ),
                expecting: Report.self
            )

            try Task.checkCancellation()

            guard report.id == currentReport.id,
                  report.evidencias.count <= 5 else {
                throw APIError.decoding
            }

            currentReport = report
            pendingImages = []
            return report
        } catch is CancellationError {
            return nil
        } catch {
            handle(error)
            return nil
        }
    }

    func delete(_ evidence: Evidence) async -> Bool {
        guard canEditReport,
              !isBusy,
              evidences.contains(where: { $0.id == evidence.id }),
              !Task.isCancelled else {
            return false
        }

        isDeleting = true
        errorMessage = nil

        defer {
            isDeleting = false
        }

        do {
            try await api.sendWithoutResponse(
                Endpoint(
                    path:
                        "reports/\(currentReport.id)/evidences/\(evidence.id)",
                    method: .delete
                )
            )

            try Task.checkCancellation()

            // La eliminación devuelve 204, sin un reporte actualizado.
            // Conservamos sus campos y retiramos la evidencia eliminada.
            let report = currentReport

            currentReport = Report(
                id: report.id,
                titulo: report.titulo,
                descripcion: report.descripcion,
                urlPublicacion: report.urlPublicacion,
                plataforma: report.plataforma,
                plataformaOtra: report.plataformaOtra,
                categoria: report.categoria,
                estado: report.estado,
                anonimo: report.anonimo,
                autor: report.autor,
                esMio: report.esMio,
                likedByMe: report.likedByMe,
                totalLikes: report.totalLikes,
                totalComentarios: report.totalComentarios,
                evidencias: report.evidencias.filter {
                    $0.id != evidence.id
                },
                revision: report.revision,
                fechaCreacion: report.fechaCreacion,
                fechaActualizacion: report.fechaActualizacion
            )

            return true
        } catch is CancellationError {
            return false
        } catch {
            handle(error)
            return false
        }
    }

    private func handle(_ error: Error) {
        guard let apiError = error as? APIError else {
            errorMessage =
                "No se pudieron actualizar las evidencias. Intenta de nuevo."
            return
        }

        switch apiError {
        case .validation(let code):
            switch code {
            case "REPORT_NOT_EDITABLE":
                isNoLongerEditable = true
                errorMessage =
                    "Este reporte ya fue revisado y no se puede modificar."

            case "INVALID_IMAGE":
                errorMessage =
                    "Una de las imágenes no es válida. Quítala e intenta de nuevo."

            case "EVIDENCE_LIMIT":
                errorMessage = "Máximo 5 imágenes por reporte."

            default:
                errorMessage =
                    "No se pudieron actualizar las evidencias. Intenta de nuevo."
            }

        case .offline:
            errorMessage =
                "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .unauthorized:
            errorMessage =
                "Tu sesión expiró. Inicia sesión de nuevo."

        case .forbidden:
            errorMessage =
                "No tienes permiso para modificar estas evidencias."

        case .notFound:
            errorMessage =
                "El reporte o la evidencia ya no están disponibles."

        case .rateLimited:
            errorMessage =
                "Demasiadas solicitudes. Espera un momento e inténtalo de nuevo."

        default:
            errorMessage =
                "No se pudieron actualizar las evidencias. Intenta de nuevo."
        }
    }
}
