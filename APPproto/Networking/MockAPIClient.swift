//
//  MockAPIClient.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

actor MockAPIClient: APIClient {
    private var forcedError: APIError?

    private let platforms: [[String: Any]]
    private let categories: [[String: Any]]
    private var reports: [[String: Any]]
    private var notifications: [[String: Any]]
    private var commentsByReport: [Int: [[String: Any]]]
    private var flaggedCommentIDs: Set<Int> = []

    private var nextCommentID = 2501
    private var nextEvidenceID = 1
    private var nextReportID = 26

    init(forcedError: APIError? = nil) async {
        self.forcedError = forcedError

        let platforms: [[String: Any]] = [
            ["id": 1, "nombre": "Facebook Marketplace", "esOtra": false],
            ["id": 2, "nombre": "Instagram", "esOtra": false],
            ["id": 3, "nombre": "WhatsApp", "esOtra": false],
            ["id": 4, "nombre": "Otra", "esOtra": true]
        ]

        let categoryNames = [
            "Producto no entregado",
            "Producto falsificado",
            "Producto distinto al anunciado",
            "Vendedor falso o suplantación",
            "Sitio o enlace fraudulento",
            "Cobro no autorizado",
            "Precio engañoso",
            "Otro"
        ]

        let categories: [[String: Any]] = categoryNames.enumerated().map {
            index, name in

            [
                "id": index + 1,
                "nombre": name,
                "descripcion": NSNull()
            ]
        }

        self.platforms = platforms
        self.categories = categories

        let states = ["pendiente", "validado", "rechazado"]
        var initialReports: [[String: Any]] = []
        var initialComments: [Int: [[String: Any]]] = [:]

        for id in 1...25 {
            let state = states[(id - 1) % states.count]
            let anonymous = id.isMultiple(of: 2)
            let date = String(
                format: "2026-10-%02dT12:00:00.000Z",
                id
            )

            var report: [String: Any] = [
                "id": id,
                "titulo": "Compra con posible fraude \(id)",
                "descripcion":
                    "Después de realizar el pago, el vendedor dejó de responder.",
                "urlPublicacion":
                    "https://example.com/publicaciones/\(id)",
                "plataforma": platforms[(id - 1) % platforms.count],
                "plataformaOtra": id.isMultiple(of: 4)
                    ? "Tienda de ejemplo"
                    : NSNull(),
                "categoria": categories[(id - 1) % categories.count],
                "estado": state,
                "anonimo": anonymous,
                "autor": NSNull(),
                "esMio": id.isMultiple(of: 5),
                "likedByMe": false,
                "totalLikes": id * 2,
                "totalComentarios": 1,
                "evidencias": [],
                "revision": NSNull(),
                "fechaCreacion": date,
                "fechaActualizacion": date
            ]

            if !anonymous {
                report["autor"] = [
                    "nombre": "Persona de ejemplo \(id)"
                ]
            }

            if state != "pendiente" {
                report["revision"] = [
                    "decision": state,
                    "comentario": state == "validado"
                        ? "El reporte fue validado."
                        : "No se pudo corroborar la información.",
                    "fecha": date
                ]
            }

            initialReports.append(report)

            initialComments[id] = [
                [
                    "id": id * 100,
                    "contenido":
                        "Gracias por compartir esta información.",
                    "anonimo": false,
                    "autor": ["nombre": "Persona de ejemplo"],
                    "esMio": false,
                    "fechaCreacion": date
                ]
            ]
        }

        reports = initialReports
        commentsByReport = initialComments

        let notificationTypes = [
            "reporte_validado",
            "reporte_rechazado",
            "nuevo_comentario",
            "comentario_ocultado"
        ]

        let notificationMessages = [
            "Tu reporte fue validado.",
            "Tu reporte fue rechazado.",
            "Tu reporte recibió un comentario.",
            "Un comentario fue ocultado por moderación."
        ]

        notifications = notificationTypes.enumerated().map {
            index, type in

            [
                "id": index + 1,
                "tipo": type,
                "mensaje": notificationMessages[index],
                "leida": false,
                "reporteId": 5,
                "fechaCreacion": "2026-10-06T12:00:00.000Z"
            ]
        }
    }

    func setForcedError(_ error: APIError?) {
        forcedError = error
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        expecting responseType: Response.Type
    ) async throws -> Response {
        try await simulateDelay()

        let segments = endpoint.path.split(separator: "/")
        let object: Any

        if endpoint.method == .get {
            object = try responseObject(for: endpoint)
        } else if endpoint.method == .post,
                  segments.count == 1,
                  segments[0] == "reports" {
            object = try createReport(endpoint: endpoint)
        } else if endpoint.method == .patch,
                  segments.count == 2,
                  segments[0] == "reports",
                  let id = Int(segments[1]) {
            object = try updateReport(id: id, endpoint: endpoint)
        } else if endpoint.method == .post,
                  segments.count == 3,
                  segments[0] == "reports",
                  segments[2] == "evidences",
                  let id = Int(segments[1]) {
            object = try uploadEvidences(
                reportID: id,
                endpoint: endpoint
            )
        } else if endpoint.method == .post,
                  segments.count == 3,
                  segments[0] == "reports",
                  segments[2] == "comments" {
            object = try createComment(for: endpoint)
        } else {
            object = try updateLike(for: endpoint)
        }

        do {
            let data = try JSONSerialization.data(
                withJSONObject: object
            )

            return try APIDecoder.make().decode(
                responseType,
                from: data
            )
        } catch {
            throw APIError.decoding
        }
    }

    func sendWithoutResponse(
        _ endpoint: Endpoint
    ) async throws {
        try await simulateDelay()

        let segments = endpoint.path.split(separator: "/")

        if endpoint.method == .delete,
           segments.count == 4,
           segments[0] == "reports",
           segments[2] == "evidences",
           let reportID = Int(segments[1]),
           let evidenceID = Int(segments[3]) {
            try deleteEvidence(
                reportID: reportID,
                evidenceID: evidenceID
            )
            return
        }

        if endpoint.method == .delete,
           segments.count == 2,
           segments[0] == "reports",
           let id = Int(segments[1]) {
            try deleteReport(id: id)
            return
        }

        if endpoint.method == .post,
           segments.count == 3,
           segments[0] == "comments",
           segments[2] == "flags",
           let id = Int(segments[1]) {
            try flagComment(id: id, endpoint: endpoint)
            return
        }

        if endpoint.method == .delete,
           segments.count == 2,
           segments[0] == "comments",
           let id = Int(segments[1]) {
            try deleteComment(id: id)
            return
        }

        guard endpoint.method == .patch,
              segments.first == "notifications" else {
            throw APIError.notFound
        }

        if segments.count == 2,
           segments[1] == "read-all" {
            for index in notifications.indices {
                notifications[index]["leida"] = true
            }
            return
        }

        if segments.count == 3,
           segments[2] == "read",
           let id = Int(segments[1]),
           let index = notifications.firstIndex(
               where: { $0["id"] as? Int == id }
           ) {
            notifications[index]["leida"] = true
            return
        }

        throw APIError.notFound
    }

    private func createReport(
        endpoint: Endpoint
    ) throws -> [String: Any] {
        #if DEBUG
        let payload = try MockEvidenceUpload.parse(endpoint)
        let fields = payload.fields

        guard let rawTitle = fields["titulo"],
              let rawDescription = fields["descripcion"],
              let rawURL = fields["urlPublicacion"],
              let rawPlatformID = fields["plataformaId"],
              let platformID = Int(rawPlatformID),
              let platform = platforms.first(
                  where: { $0["id"] as? Int == platformID }
              ),
              let rawCategoryID = fields["categoriaId"],
              let categoryID = Int(rawCategoryID),
              let category = categories.first(
                  where: { $0["id"] as? Int == categoryID }
              ),
              let rawAnonymous = fields["anonimo"],
              rawAnonymous == "true" || rawAnonymous == "false" else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        let title = rawTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let description = rawDescription.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let publicationURL = rawURL.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !title.isEmpty,
              rawTitle.count <= 150,
              description.count >= 20,
              rawDescription.count <= 5000,
              rawURL.count <= 2048 else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        guard validPublicationURL(publicationURL) else {
            throw APIError.validation(code: "INVALID_URL")
        }

        var otherPlatform: Any = NSNull()

        if platform["esOtra"] as? Bool == true {
            guard let rawName = fields["plataformaOtra"] else {
                throw APIError.validation(code: "INVALID_PLATFORM")
            }

            let name = rawName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !name.isEmpty, rawName.count <= 100 else {
                throw APIError.validation(code: "INVALID_PLATFORM")
            }

            otherPlatform = name
        }

        guard payload.images.count <= 5 else {
            throw APIError.validation(code: "EVIDENCE_LIMIT")
        }

        let followingReportID = nextReportID.addingReportingOverflow(1)
        let followingEvidenceID = nextEvidenceID.addingReportingOverflow(
            payload.images.count
        )

        guard !followingReportID.overflow,
              !followingEvidenceID.overflow else {
            throw APIError.server
        }

        var evidences: [[String: Any]] = []

        for (offset, image) in payload.images.enumerated() {
            try Task.checkCancellation()

            evidences.append([
                "id": nextEvidenceID + offset,
                "url":
                    "mock-evidence:jpeg;base64,"
                    + image.base64EncodedString()
            ])
        }

        let anonymous = rawAnonymous == "true"
        let date = currentTimestamp()

        var report: [String: Any] = [
            "id": nextReportID,
            "titulo": title,
            "descripcion": description,
            "urlPublicacion": publicationURL,
            "plataforma": platform,
            "plataformaOtra": otherPlatform,
            "categoria": category,
            "estado": "pendiente",
            "anonimo": anonymous,
            "autor": NSNull(),
            "esMio": true,
            "likedByMe": false,
            "totalLikes": 0,
            "totalComentarios": 0,
            "evidencias": evidences,
            "revision": NSNull(),
            "fechaCreacion": date,
            "fechaActualizacion": date
        ]

        if !anonymous {
            report["autor"] = ["nombre": "Usuario de prueba"]
        }

        try Task.checkCancellation()

        reports.append(report)
        commentsByReport[nextReportID] = []
        nextReportID = followingReportID.partialValue
        nextEvidenceID = followingEvidenceID.partialValue

        return report
        #else
        throw APIError.forbidden
        #endif
    }

    private func editableReportIndex(id: Int) throws -> Int {
        guard let index = reports.firstIndex(
            where: { $0["id"] as? Int == id }
        ) else {
            throw APIError.notFound
        }

        guard reports[index]["esMio"] as? Bool == true else {
            throw APIError.forbidden
        }

        guard reports[index]["estado"] as? String == "pendiente" else {
            throw APIError.validation(code: "REPORT_NOT_EDITABLE")
        }

        return index
    }

    private func uploadEvidences(
        reportID: Int,
        endpoint: Endpoint
    ) throws -> [String: Any] {
        #if DEBUG
        let index = try editableReportIndex(id: reportID)

        guard var evidences =
            reports[index]["evidencias"] as? [[String: Any]] else {
            throw APIError.decoding
        }

        let images = try MockEvidenceUpload.images(from: endpoint)

        guard !images.isEmpty,
              evidences.count + images.count <= 5 else {
            throw APIError.validation(code: "EVIDENCE_LIMIT")
        }

        let nextID = nextEvidenceID.addingReportingOverflow(images.count)

        guard !nextID.overflow else {
            throw APIError.server
        }

        var additions: [[String: Any]] = []

        for (offset, image) in images.enumerated() {
            try Task.checkCancellation()

            additions.append([
                "id": nextEvidenceID + offset,
                "url":
                    "mock-evidence:jpeg;base64,"
                    + image.base64EncodedString()
            ])
        }

        try Task.checkCancellation()

        evidences.append(contentsOf: additions)
        reports[index]["evidencias"] = evidences
        reports[index]["fechaActualizacion"] = currentTimestamp()
        nextEvidenceID = nextID.partialValue

        return reports[index]
        #else
        throw APIError.forbidden
        #endif
    }

    private func deleteEvidence(
        reportID: Int,
        evidenceID: Int
    ) throws {
        let index = try editableReportIndex(id: reportID)

        guard var evidences =
            reports[index]["evidencias"] as? [[String: Any]] else {
            throw APIError.decoding
        }

        guard let evidenceIndex = evidences.firstIndex(
            where: { $0["id"] as? Int == evidenceID }
        ) else {
            throw APIError.notFound
        }

        evidences.remove(at: evidenceIndex)
        reports[index]["evidencias"] = evidences
        reports[index]["fechaActualizacion"] = currentTimestamp()
    }

    private func updateReport(
        id: Int,
        endpoint: Endpoint
    ) throws -> [String: Any] {
        let index = try editableReportIndex(id: id)
        let fields = try requestFields(for: endpoint)

        let allowedFields: Set<String> = [
            "titulo",
            "descripcion",
            "urlPublicacion",
            "plataformaId",
            "plataformaOtra",
            "categoriaId",
            "anonimo"
        ]

        guard !fields.isEmpty,
              Set(fields.keys).isSubset(of: allowedFields) else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        var updated = reports[index]

        for (key, maximum, minimum) in [
            ("titulo", 150, 1),
            ("descripcion", 5000, 20),
            ("urlPublicacion", 2048, 1)
        ] {
            if let value = fields[key] {
                guard let raw = value as? String else {
                    throw APIError.validation(code: "INVALID_INPUT")
                }

                let text = raw.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                guard text.count >= minimum,
                      raw.count <= maximum else {
                    throw APIError.validation(code: "INVALID_INPUT")
                }

                updated[key] = text
            }
        }

        if let value = fields["plataformaId"] {
            guard let platformID = value as? Int,
                  let platform = platforms.first(
                      where: { $0["id"] as? Int == platformID }
                  ) else {
                throw APIError.validation(code: "INVALID_PLATFORM")
            }

            updated["plataforma"] = platform
        }

        if let value = fields["categoriaId"] {
            guard let categoryID = value as? Int,
                  let category = categories.first(
                      where: { $0["id"] as? Int == categoryID }
                  ) else {
                throw APIError.validation(code: "INVALID_CATEGORY")
            }

            updated["categoria"] = category
        }

        if let value = fields["plataformaOtra"] {
            if value is NSNull {
                updated["plataformaOtra"] = NSNull()
            } else if let name = value as? String,
                      name.count <= 100 {
                updated["plataformaOtra"] = name.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            } else {
                throw APIError.validation(code: "INVALID_PLATFORM")
            }
        }

        guard let platform =
            updated["plataforma"] as? [String: Any] else {
            throw APIError.decoding
        }

        if platform["esOtra"] as? Bool == true {
            guard let name = updated["plataformaOtra"] as? String,
                  !name.isEmpty,
                  name.count <= 100 else {
                throw APIError.validation(code: "INVALID_PLATFORM")
            }
        } else {
            updated["plataformaOtra"] = NSNull()
        }

        guard let publicationURL = updated["urlPublicacion"] as? String,
              validPublicationURL(publicationURL) else {
            throw APIError.validation(code: "INVALID_URL")
        }

        if let value = fields["anonimo"] {
            guard let anonymous = value as? Bool else {
                throw APIError.validation(code: "INVALID_INPUT")
            }

            updated["anonimo"] = anonymous

            if anonymous {
                updated["autor"] = NSNull()
            } else {
                updated["autor"] = ["nombre": "Usuario de prueba"]
            }
        }

        updated["fechaActualizacion"] = currentTimestamp()
        reports[index] = updated

        return updated
    }

    private func deleteReport(id: Int) throws {
        guard let index = reports.firstIndex(
            where: { $0["id"] as? Int == id }
        ) else {
            throw APIError.notFound
        }

        guard reports[index]["esMio"] as? Bool == true else {
            throw APIError.forbidden
        }

        guard reports[index]["estado"] as? String == "pendiente" else {
            throw APIError.conflict
        }

        let removedComments = commentsByReport.removeValue(
            forKey: id
        ) ?? []

        for comment in removedComments {
            if let commentID = comment["id"] as? Int {
                flaggedCommentIDs.remove(commentID)
            }
        }

        reports.remove(at: index)

        notifications.removeAll {
            $0["reporteId"] as? Int == id
        }
    }

    private func flagComment(
        id: Int,
        endpoint: Endpoint
    ) throws {
        guard let comment = commentsByReport.values
            .flatMap({ $0 })
            .first(where: { $0["id"] as? Int == id }) else {
            throw APIError.notFound
        }

        guard comment["esMio"] as? Bool == false else {
            throw APIError.forbidden
        }

        let fields = try requestFields(for: endpoint)

        guard let reason = fields["motivo"] as? String,
              CommentFlagReason(rawValue: reason) != nil else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        if let rawDetail = fields["detalle"] {
            guard let detail = rawDetail as? String,
                  detail.count <= 255 else {
                throw APIError.validation(code: "INVALID_DETAIL")
            }
        }

        guard !flaggedCommentIDs.contains(id) else {
            throw APIError.validation(code: "ALREADY_FLAGGED")
        }

        flaggedCommentIDs.insert(id)
    }

    private func deleteComment(id: Int) throws {
        for report in reports {
            guard let reportID = report["id"] as? Int,
                  var comments = commentsByReport[reportID],
                  let commentIndex = comments.firstIndex(
                      where: { $0["id"] as? Int == id }
                  ) else {
                continue
            }

            guard comments[commentIndex]["esMio"] as? Bool == true else {
                throw APIError.forbidden
            }

            guard let reportIndex = reports.firstIndex(
                where: { $0["id"] as? Int == reportID }
            ) else {
                throw APIError.notFound
            }

            comments.remove(at: commentIndex)
            commentsByReport[reportID] = comments
            reports[reportIndex]["totalComentarios"] = comments.count
            flaggedCommentIDs.remove(id)

            return
        }

        throw APIError.notFound
    }

    private func createComment(
        for endpoint: Endpoint
    ) throws -> [String: Any] {
        let segments = endpoint.path.split(separator: "/")

        guard endpoint.method == .post,
              segments.count == 3,
              segments[0] == "reports",
              segments[2] == "comments",
              let reportID = Int(segments[1]),
              let reportIndex = reports.firstIndex(
                  where: { $0["id"] as? Int == reportID }
              ) else {
            throw APIError.notFound
        }

        let fields = try requestFields(for: endpoint)

        guard let rawContent = fields["contenido"] as? String,
              let anonymous = fields["anonimo"] as? Bool else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        let content = rawContent.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !content.isEmpty,
              rawContent.count <= 1000 else {
            throw APIError.validation(code: "INVALID_COMMENT")
        }

        let nextID = nextCommentID.addingReportingOverflow(1)

        guard !nextID.overflow else {
            throw APIError.server
        }

        var comment: [String: Any] = [
            "id": nextCommentID,
            "contenido": content,
            "anonimo": anonymous,
            "autor": NSNull(),
            "esMio": true,
            "fechaCreacion": currentTimestamp()
        ]

        if !anonymous {
            comment["autor"] = ["nombre": "Usuario de prueba"]
        }

        var comments = commentsByReport[reportID] ?? []
        comments.insert(comment, at: 0)

        commentsByReport[reportID] = comments
        reports[reportIndex]["totalComentarios"] = comments.count
        nextCommentID = nextID.partialValue

        return comment
    }

    private func updateLike(
        for endpoint: Endpoint
    ) throws -> [String: Any] {
        let segments = endpoint.path.split(separator: "/")

        guard endpoint.method == .post || endpoint.method == .delete,
              segments.count == 3,
              segments[0] == "reports",
              segments[2] == "like",
              let id = Int(segments[1]),
              let index = reports.firstIndex(
                  where: { $0["id"] as? Int == id }
              ) else {
            throw APIError.notFound
        }

        guard reports[index]["esMio"] as? Bool != true else {
            throw APIError.forbidden
        }

        guard let previousLiked = reports[index]["likedByMe"] as? Bool,
              let previousCount = reports[index]["totalLikes"] as? Int,
              previousCount >= 0 else {
            throw APIError.decoding
        }

        let requestedLiked = endpoint.method == .post
        var count = previousCount

        if requestedLiked != previousLiked {
            if requestedLiked {
                let result = count.addingReportingOverflow(1)

                guard !result.overflow else {
                    throw APIError.decoding
                }

                count = result.partialValue
            } else {
                count = max(0, count - 1)
            }
        }

        reports[index]["likedByMe"] = requestedLiked
        reports[index]["totalLikes"] = count

        return [
            "totalLikes": count,
            "likedByMe": requestedLiked
        ]
    }

    private func requestFields(
        for endpoint: Endpoint
    ) throws -> [String: Any] {
        guard let body = endpoint.body,
              let object = try? JSONSerialization.jsonObject(with: body),
              let fields = object as? [String: Any] else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        return fields
    }

    private func validPublicationURL(_ value: String) -> Bool {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty,
              components.user == nil,
              components.password == nil,
              components.url != nil else {
            return false
        }

        return true
    }

    private func currentTimestamp() -> String {
        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        return formatter.string(from: Date())
    }

    private func simulateDelay() async throws {
        try await Task.sleep(for: .milliseconds(500))
        try Task.checkCancellation()

        if let forcedError {
            throw forcedError
        }
    }

    private func responseObject(
        for endpoint: Endpoint
    ) throws -> Any {
        let segments = endpoint.path.split(separator: "/")
        let path = segments.joined(separator: "/")

        switch path {
        case "platforms":
            return platforms

        case "categories":
            return categories

        case "me":
            return [
                "nombre": "Usuario de prueba",
                "correo": "demo@clicksafe.mx",
                "rol": "usuario",
                "fechaRegistro": "2026-09-01T12:00:00.000Z",
                "totpActivo": false
            ]

        case "reports", "me/reports":
            var items = reports

            if path == "me/reports" {
                items = items.filter {
                    $0["esMio"] as? Bool == true
                }
            }

            items = filteredReports(items, endpoint: endpoint)
            return try paginated(items, endpoint: endpoint)

        case "notifications":
            var items = notifications

            if let readValue = query("leida", in: endpoint) {
                guard readValue == "true" || readValue == "false" else {
                    throw APIError.validation(code: "INVALID_QUERY")
                }

                let read = readValue == "true"

                items = items.filter {
                    $0["leida"] as? Bool == read
                }
            }

            return try paginated(items, endpoint: endpoint)

        case "notifications/unread-count":
            return [
                "count": notifications.filter {
                    $0["leida"] as? Bool == false
                }.count
            ]

        default:
            break
        }

        if segments.first == "reports",
           segments.count >= 2,
           let id = Int(segments[1]),
           let report = reports.first(
               where: { $0["id"] as? Int == id }
           ) {
            if segments.count == 2 {
                return report
            }

            if segments.count == 3,
               segments[2] == "comments" {
                return try paginated(
                    commentsByReport[id] ?? [],
                    endpoint: endpoint
                )
            }
        }

        throw APIError.notFound
    }

    private func filteredReports(
        _ reports: [[String: Any]],
        endpoint: Endpoint
    ) -> [[String: Any]] {
        var items = reports

        if let search = query("q", in: endpoint),
           !search.isEmpty {
            items = items.filter {
                let title = $0["titulo"] as? String ?? ""
                let description = $0["descripcion"] as? String ?? ""
                let publicationURL = $0["urlPublicacion"] as? String ?? ""

                return title.localizedCaseInsensitiveContains(search)
                    || description.localizedCaseInsensitiveContains(search)
                    || publicationURL.localizedCaseInsensitiveContains(search)
            }
        }

        if let state = query("estado", in: endpoint) {
            items = items.filter {
                $0["estado"] as? String == state
            }
        }

        for key in ["plataforma", "categoria"] {
            if let value = query(key, in: endpoint),
               let id = Int(value) {
                items = items.filter {
                    let object = $0[key] as? [String: Any]
                    return object?["id"] as? Int == id
                }
            }
        }

        if query("orden", in: endpoint) == "populares" {
            items.sort {
                ($0["totalLikes"] as? Int ?? 0)
                    > ($1["totalLikes"] as? Int ?? 0)
            }
        } else {
            items.sort {
                ($0["fechaCreacion"] as? String ?? "")
                    > ($1["fechaCreacion"] as? String ?? "")
            }
        }

        return items
    }

    private func paginated(
        _ items: [[String: Any]],
        endpoint: Endpoint
    ) throws -> [String: Any] {
        let page = try positiveInteger(
            query("page", in: endpoint),
            defaultValue: 1
        )

        let limit = try positiveInteger(
            query("limit", in: endpoint),
            defaultValue: 20
        )

        guard limit <= 100 else {
            throw APIError.validation(code: "INVALID_PAGINATION")
        }

        let offset = (page - 1).multipliedReportingOverflow(
            by: limit
        )

        guard !offset.overflow else {
            throw APIError.validation(code: "INVALID_PAGINATION")
        }

        return [
            "items": Array(
                items.dropFirst(offset.partialValue).prefix(limit)
            ),
            "page": page,
            "limit": limit,
            "total": items.count
        ]
    }

    private func positiveInteger(
        _ value: String?,
        defaultValue: Int
    ) throws -> Int {
        guard let value else {
            return defaultValue
        }

        guard let number = Int(value), number > 0 else {
            throw APIError.validation(code: "INVALID_PAGINATION")
        }

        return number
    }

    private func query(
        _ name: String,
        in endpoint: Endpoint
    ) -> String? {
        endpoint.queryItems.first {
            $0.name == name
        }?.value
    }
}
