//
//  MockEvidenceUpload.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation

nonisolated enum MockEvidenceUpload {
    nonisolated struct Payload: Sendable {
        let fields: [String: String]
        let images: [Data]
    }

    static func images(from endpoint: Endpoint) throws -> [Data] {
        let payload = try parse(endpoint)

        guard payload.fields.isEmpty,
              !payload.images.isEmpty else {
            throw APIError.validation(code: "INVALID_IMAGE")
        }

        return payload.images
    }

    static func parse(_ endpoint: Endpoint) throws -> Payload {
        let contentTypePrefix = "multipart/form-data; boundary="

        guard endpoint.contentType.hasPrefix(contentTypePrefix),
              let body = endpoint.body,
              !body.isEmpty else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        let boundary = String(
            endpoint.contentType.dropFirst(contentTypePrefix.count)
        )

        let allowedCharacters = CharacterSet(
            charactersIn:
                "abcdefghijklmnopqrstuvwxyz"
                + "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                + "0123456789-"
        )

        guard !boundary.isEmpty,
              boundary.count <= 70,
              boundary.unicodeScalars.allSatisfy({
                  allowedCharacters.contains($0)
              }) else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        let fieldLimits: [String: Int] = [
            "titulo": 150,
            "descripcion": 5000,
            "urlPublicacion": 2048,
            "plataformaId": 20,
            "plataformaOtra": 100,
            "categoriaId": 20,
            "anonimo": 5
        ]

        let opening = Data("--\(boundary)\r\n".utf8)
        let headerEnd = Data("\r\n\r\n".utf8)
        let separator = Data("\r\n--\(boundary)".utf8)
        let nextPart = Data("\r\n".utf8)
        let closing = Data("--\r\n".utf8)

        guard body.starts(with: opening) else {
            throw APIError.validation(code: "INVALID_INPUT")
        }

        var cursor = opening.count
        var fields: [String: String] = [:]
        var images: [Data] = []

        while cursor < body.count {
            try Task.checkCancellation()

            guard let headerRange = body.range(
                of: headerEnd,
                in: cursor..<body.count
            ),
            headerRange.lowerBound - cursor <= 1024,
            let header = String(
                data: body.subdata(
                    in: cursor..<headerRange.lowerBound
                ),
                encoding: .utf8
            ) else {
                throw APIError.validation(code: "INVALID_INPUT")
            }

            let contentStart = headerRange.upperBound

            guard let separatorRange = body.range(
                of: separator,
                in: contentStart..<body.count
            ) else {
                throw APIError.validation(code: "INVALID_INPUT")
            }

            let content = body.subdata(
                in: contentStart..<separatorRange.lowerBound
            )

            let fileHeaderPrefix =
                "Content-Disposition: form-data; "
                + "name=\"evidencias\"; filename="

            if header.hasPrefix(fileHeaderPrefix) {
                guard images.count < 5 else {
                    throw APIError.validation(code: "EVIDENCE_LIMIT")
                }

                let number = images.count + 1
                let expectedHeader =
                    fileHeaderPrefix
                    + "\"evidencia-\(number).jpg\"\r\n"
                    + "Content-Type: image/jpeg"

                guard header == expectedHeader,
                      content.count <= 5 * 1024 * 1024,
                      content.starts(with: [0xFF, 0xD8, 0xFF]) else {
                    throw APIError.validation(code: "INVALID_IMAGE")
                }

                images.append(content)
            } else {
                guard let fieldName = fieldLimits.keys.first(
                    where: {
                        header ==
                            "Content-Disposition: form-data; name=\"\($0)\""
                    }
                ),
                fields[fieldName] == nil,
                let limit = fieldLimits[fieldName],
                let value = String(data: content, encoding: .utf8),
                value.count <= limit else {
                    throw APIError.validation(code: "INVALID_INPUT")
                }

                fields[fieldName] = value
            }

            cursor = separatorRange.upperBound

            if body.count - cursor == closing.count,
               body.subdata(in: cursor..<body.count) == closing {
                try Task.checkCancellation()

                return Payload(
                    fields: fields,
                    images: images
                )
            }

            guard body.count - cursor >= nextPart.count,
                  body.subdata(
                    in: cursor..<(cursor + nextPart.count)
                  ) == nextPart else {
                throw APIError.validation(code: "INVALID_INPUT")
            }

            cursor += nextPart.count
        }

        throw APIError.validation(code: "INVALID_INPUT")
    }
}
