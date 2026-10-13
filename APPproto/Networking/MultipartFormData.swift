//
//  MultipartFormData.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation

nonisolated struct MultipartFormData: Sendable {
    private let boundary = "Boundary-\(UUID().uuidString)"
    private var parts = Data()

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    var body: Data {
        var result = parts
        result.append(Data("--\(boundary)--\r\n".utf8))
        return result
    }

    mutating func addField(
        name: String,
        value: String
    ) throws {
        guard isValidName(name),
              !value.contains(boundary) else {
            throw MultipartFormDataError.invalidField
        }

        append("--\(boundary)\r\n")
        append(
            "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        )
        append("\r\n")
        append(value)
        append("\r\n")
    }

    mutating func addEvidence(
        jpegData: Data,
        number: Int
    ) throws {
        guard (1...5).contains(number),
              !jpegData.isEmpty,
              jpegData.count <= 5 * 1024 * 1024,
              jpegData.starts(with: [0xFF, 0xD8, 0xFF]),
              jpegData.range(of: Data(boundary.utf8)) == nil else {
            throw MultipartFormDataError.invalidEvidence
        }

        append("--\(boundary)\r\n")
        append(
            "Content-Disposition: form-data; name=\"evidencias\"; filename=\"evidencia-\(number).jpg\"\r\n"
        )
        append("Content-Type: image/jpeg\r\n")
        append("\r\n")
        parts.append(jpegData)
        append("\r\n")
    }

    private mutating func append(_ value: String) {
        parts.append(Data(value.utf8))
    }

    private func isValidName(_ name: String) -> Bool {
        let allowed = CharacterSet(
            charactersIn:
                "abcdefghijklmnopqrstuvwxyz"
                + "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                + "0123456789_-"
        )

        return !name.isEmpty
            && name.unicodeScalars.allSatisfy {
                allowed.contains($0)
            }
    }
}

nonisolated enum MultipartFormDataError: LocalizedError {
    case invalidField
    case invalidEvidence

    var errorDescription: String? {
        switch self {
        case .invalidField:
            return "No se pudo preparar un campo del formulario."

        case .invalidEvidence:
            return "No se pudo preparar una imagen de evidencia."
        }
    }
}
