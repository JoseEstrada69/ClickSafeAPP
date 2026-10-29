//
//  APIError.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation

enum APIError: Error, Sendable {
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validation(code: String)
    case rateLimited
    case server
    case offline
    case decoding

    var userMessage: String {
        switch self {
        case .offline:
            return "No hay conexión. Revisa tu internet e inténtalo de nuevo."

        case .rateLimited:
            return "Demasiados intentos. Espera un momento e inténtalo de nuevo."

        case .notFound:
            return "No encontramos lo que buscas. Puede que ya no exista."

        case .server:
            return "Algo salió mal de nuestro lado. Inténtalo más tarde."

        case .validation(let code):
            switch code {
            case "CAPTCHA_INVALID":
                return "No pudimos verificar la solicitud. Inténtalo de nuevo."
            case "INVALID_CODE":
                return "Código incorrecto o expirado."
            default:
                return "No se pudo completar la acción."
            }

        case .unauthorized, .forbidden, .conflict, .decoding:
            return "No se pudo completar la acción."
        }
    }
}
