//
//  Route.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 07/10/26.
//

nonisolated enum Route: Hashable {
    case login
    case register
    case verifyEmail(correo: String)
    case forgotPassword
}
