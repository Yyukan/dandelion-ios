//
//  SignInWebView.swift
//  Dandelion
//
//  Hosts the opencode.ai sign-in page in a WKWebView backed by the app's own
//  WKWebsiteDataStore.default() - unlike ASWebAuthenticationSession, whose
//  non-ephemeral cookie jar is shared with Safari rather than with the host
//  app's own web view storage, cookies set here land exactly where
//  SessionAuthService reads them back from. Normally auto-dismisses the
//  moment the "auth" cookie for opencode.ai appears, but also offers a
//  manual Done button - as a visible way out if the page doesn't trigger a
//  cookie-store notification promptly, Done re-checks the same store once
//  more before closing.
//

import SwiftUI
import WebKit

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
            if let authCookie = cookies.first(where: { $0.domain.hasSuffix("opencode.ai") && $0.name == "auth" }) {
                onSignedIn(authCookie.value)
            }
            dismiss()
        }
    }
}

/// UIKit bridge: a `WKWebView` whose website data store is the app's own
/// `.default()` store, with a cookie-store observer that reports the
/// opencode.ai "auth" cookie the instant it's set.
private struct CookieWatchingWebView: UIViewRepresentable {
    let url: URL
    var onAuthCookie: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onAuthCookie: onAuthCookie)
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
        private let onAuthCookie: (String) -> Void
        private var reported = false

        init(onAuthCookie: @escaping (String) -> Void) {
            self.onAuthCookie = onAuthCookie
        }

        func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
            guard !reported else { return }
            cookieStore.getAllCookies { [weak self] cookies in
                guard let self, !self.reported,
                      let authCookie = cookies.first(where: { $0.domain.hasSuffix("opencode.ai") && $0.name == "auth" })
                else { return }
                self.reported = true
                Task { @MainActor in
                    self.onAuthCookie(authCookie.value)
                }
            }
        }
    }
}

#Preview {
    SignInWebView(url: URL(string: "https://opencode.ai/zen")!) { _ in }
}
