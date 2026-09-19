//
//  SignInWebView.swift
//  Dandelion
//
//  Hosts the OpenCode console sign-in page (https://opencode.ai/console/) in
//  a WKWebView backed by the app's own WKWebsiteDataStore.default() - unlike
//  ASWebAuthenticationSession, whose non-ephemeral cookie jar is shared with
//  Safari rather than with the host app's own web view storage, cookies set
//  here land exactly where SessionAuthService reads them back from. Normally
//  auto-dismisses the moment the `__Host-console_session` cookie for
//  opencode.ai appears, but also offers a manual Done button - as a visible
//  way out if the page doesn't trigger a cookie-store notification promptly,
//  Done re-checks the same store once more before closing.
//
//  GitHub is the reliable sign-in here: Google blocks OAuth inside embedded
//  web views, so the footer nudges towards GitHub.
//

import SwiftUI
import WebKit

/// The console's session cookie, as set by opencode.ai after sign-in.
private let consoleSessionCookieName = "__Host-console_session"

struct SignInWebView: View {
    let url: URL
    var onSignedIn: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CookieWatchingWebView(url: url) { cookieValue in
                onSignedIn(cookieValue)
                dismiss()
            }
            .safeAreaInset(edge: .bottom) {
                Text("Sign in with GitHub - Google may block OAuth inside this web view.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.bar)
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { finishAndDismiss() }
                }
            }
        }
    }

    private func finishAndDismiss() {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            if let sessionCookie = cookies.first(where: {
                $0.domain.hasSuffix("opencode.ai") && $0.name == consoleSessionCookieName
            }) {
                onSignedIn(sessionCookie.value)
            }
            dismiss()
        }
    }
}

/// UIKit bridge: a `WKWebView` whose website data store is the app's own
/// `.default()` store, with a cookie-store observer that reports the
/// opencode.ai console session cookie the instant it's set.
private struct CookieWatchingWebView: UIViewRepresentable {
    let url: URL
    var onSessionCookie: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSessionCookie: onSessionCookie)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        configuration.websiteDataStore.httpCookieStore.add(context.coordinator)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.websiteDataStore.httpCookieStore.remove(coordinator)
    }

    final class Coordinator: NSObject, WKHTTPCookieStoreObserver {
        private let onSessionCookie: (String) -> Void
        private var reported = false

        init(onSessionCookie: @escaping (String) -> Void) {
            self.onSessionCookie = onSessionCookie
        }

        func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
            guard !reported else { return }
            cookieStore.getAllCookies { [weak self] cookies in
                guard let self, !self.reported,
                      let sessionCookie = cookies.first(where: {
                          $0.domain.hasSuffix("opencode.ai") && $0.name == consoleSessionCookieName
                      })
                else { return }
                self.reported = true
                Task { @MainActor in
                    self.onSessionCookie(sessionCookie.value)
                }
            }
        }
    }
}

#Preview {
    SignInWebView(url: URL(string: "https://opencode.ai/console/")!) { _ in }
}
