//
//  SessionAuthService.swift
//  Dandelion
//
//  The iOS sandbox gives an app no access whatsoever to another app's
//  container or Keychain items, so there's no way to auto-discover a
//  browser's cookie store. Instead this drives a one-time in-app sign-in
//  through a WKWebView the app hosts itself (see SignInWebView), backed by
//  the app's own WKWebsiteDataStore.default() - the same store the login
//  page's cookies land in, and the same one this reads back from.
//
//  An ASWebAuthenticationSession was tried first, since its non-ephemeral
//  mode advertises sharing cookies "with the user's normal browser session" -
//  but that shared jar turned out to be Safari's own data store, which is
//  isolated from the host app's WKWebsiteDataStore.default() and never
//  observable here, so the captured cookie was never actually found.
//

import Foundation
import Observation

@MainActor
@Observable
final class SessionAuthService {
    let signInURL = URL(string: "https://opencode.ai/zen")!

    private let cookieStore: SessionCookieStore

    /// Stored (not computed) so @Observable can actually notify SwiftUI when
    /// it changes - a computed property reading straight from the Keychain
    /// never fires observation, since no tracked stored access happens on
    /// sign-in/sign-out.
    private(set) var isSignedIn: Bool

    init(cookieStore: SessionCookieStore = SessionCookieStore()) {
        self.cookieStore = cookieStore
        self.isSignedIn = cookieStore.load() != nil
    }

    /// Called by `SignInWebView` once it observes the "auth" cookie appear
    /// in its (shared, `.default()`) website data store.
    func completeSignIn(cookieValue: String) {
        cookieStore.save(cookieValue)
        isSignedIn = true
    }

    func signOut() {
        cookieStore.clear()
        isSignedIn = false
    }
}
