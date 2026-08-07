//
//  SessionCookieStore.swift
//  Dandelion
//
//  Stores the user's opencode.ai session cookie in the iOS Keychain (never
//  plaintext). This is the only place the cookie lives: it's captured once
//  via SessionAuthService's in-app sign-in and persisted here for every
//  future launch.
//

import Foundation
import Security

/// The opencode.ai session cookie value, as consumed by `UsageService`.
struct SessionCookie: Sendable, Equatable {
    let value: String
}

struct SessionCookieStore: Sendable {
    private static let service = "nl.ostconsultancy.Dandelion"
    private static let account = "opencode-session-cookie"

    func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty
        else { return nil }
        return value
    }

    func save(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clear()
            return
        }

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
        ]
        let data = Data(trimmed.utf8)

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status == errSecDuplicateItem {
            SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        }
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
