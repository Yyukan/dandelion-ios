//
//  APIKeyStore.swift
//  Dandelion
//
//  Stores the user's OpenCode API key in the iOS Keychain (never plaintext).
//  iOS is sandboxed and cannot read OpenCode's local
//  `~/.local/share/opencode/auth.json`, so - unlike the macOS app, which
//  auto-discovers the key there - the key is pasted once in Settings and read
//  back by `UsageService` on every refresh.
//
//  One key covers both surfaces the app shows: the console's billing JSON API
//  (Zen balance) and Go usage. Both authenticate with
//  `Authorization: Bearer <key>`; there is no sign-in, no browser session and
//  no cookie jar involved anywhere.
//
//  The Keychain account string is deliberately unchanged from when this store
//  only held the Go key, so an already-saved key survives this rename.
//

import Foundation
import Security

struct APIKeyStore: Sendable {
    private static let service = "nl.ostconsultancy.Dandelion"
    private static let account = "opencode-go-api-key"

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
