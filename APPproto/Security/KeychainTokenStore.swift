//
//  KeychainTokenStore.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 06/10/26.
//

import Foundation
import Security

actor KeychainTokenStore {
    enum StoreError: Error, Sendable {
        case invalidToken
        case invalidStoredData
        case unexpectedStatus(OSStatus)
    }

    private let service = "mx.clicksafe.session"
    private let account: String

    init(account: String = "refreshToken") {
        self.account = account
    }
    func saveRefreshToken(_ token: String) throws {
        guard !token.isEmpty else {
            throw StoreError.invalidToken
        }

        let data = Data(token.utf8)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(
            itemQuery as CFDictionary,
            attributes as CFDictionary
        )

        switch updateStatus {
        case errSecSuccess:
            return

        case errSecItemNotFound:
            var query = itemQuery
            query.merge(attributes) { _, newValue in newValue }

            let addStatus = SecItemAdd(
                query as CFDictionary,
                nil
            )

            guard addStatus == errSecSuccess else {
                throw StoreError.unexpectedStatus(addStatus)
            }

        default:
            throw StoreError.unexpectedStatus(updateStatus)
        }
    }

    func loadRefreshToken() throws -> String? {
        var query = itemQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw StoreError.unexpectedStatus(status)
        }

        guard
            let data = result as? Data,
            let token = String(data: data, encoding: .utf8),
            !token.isEmpty
        else {
            throw StoreError.invalidStoredData
        }

        return token
    }

    func deleteRefreshToken() throws {
        let status = SecItemDelete(itemQuery as CFDictionary)

        guard
            status == errSecSuccess ||
            status == errSecItemNotFound
        else {
            throw StoreError.unexpectedStatus(status)
        }
    }

    private var itemQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false
        ]
    }
}
