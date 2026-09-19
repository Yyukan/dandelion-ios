//
//  SettingsView.swift
//  Dandelion
//
//  OpenCode console sign-in status, the OpenCode Go API key, and the
//  auto-refresh interval picker. iOS has no local auth.json or browser
//  cookie jar to auto-discover, so both credentials are first-class,
//  user-initiated actions here: the console session comes from an in-app
//  WKWebView sign-in (see SessionAuthService), and the Go key is pasted
//  into the SecureField below (see GoAPIKeyStore).
//

import SwiftUI

struct SettingsView: View {
    let model: AppModel

    @Environment(\.dismiss) private var dismiss
    @State private var showSignIn = false
    @State private var goAPIKey = ""
    @State private var hasGoAPIKey = false

    private let goAPIKeyStore = GoAPIKeyStore()

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                goKeySection
                refreshSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(TerminalTheme.Colors.background)
            .foregroundStyle(TerminalTheme.Colors.textPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showSignIn) {
                SignInWebView(url: model.authService.signInURL) { cookieValue in
                    Task { await model.finishSignIn(cookieValue: cookieValue) }
                }
            }
            .task { hasGoAPIKey = goAPIKeyStore.load() != nil }
        }
    }

    private var accountSection: some View {
        Section("OpenCode Account") {
            if model.authService.isSignedIn {
                Label("Signed in", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(TerminalTheme.Colors.accent)
                Button("Sign Out", role: .destructive) {
                    model.authService.signOut()
                    Task { await model.refreshCoordinator.refreshNow() }
                    dismiss()
                }
            } else {
                Text("Sign in to the OpenCode console to see your live Zen balance.")
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
            }

            Button(model.authService.isSignedIn ? "Sign In Again" : "Sign In") {
                showSignIn = true
            }

            Text("Sign in with GitHub - Google may block OAuth inside the app's web view.")
                .font(TerminalTheme.Fonts.caption)
                .foregroundStyle(TerminalTheme.Colors.textTertiary)
        }
    }

    private var goKeySection: some View {
        Section("OpenCode Go") {
            SecureField("API key", text: $goAPIKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Save Key", action: saveGoAPIKey)
                .disabled(goAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if hasGoAPIKey {
                Button("Remove Key", role: .destructive, action: removeGoAPIKey)
            }

            Text("Go usage needs an API key; create one at opencode.ai/docs/go.")
                .font(TerminalTheme.Fonts.caption)
                .foregroundStyle(TerminalTheme.Colors.textSecondary)
        }
    }

    private func saveGoAPIKey() {
        goAPIKeyStore.save(goAPIKey)
        goAPIKey = ""
        hasGoAPIKey = goAPIKeyStore.load() != nil
        Task { await model.refreshCoordinator.refreshNow() }
    }

    private func removeGoAPIKey() {
        goAPIKeyStore.clear()
        hasGoAPIKey = false
        Task { await model.refreshCoordinator.refreshNow() }
    }

    private var refreshSection: some View {
        Section("Refresh") {
            Toggle("Auto-refresh", isOn: Binding(
                get: { model.appSettings.autoRefreshEnabled },
                set: { model.refreshCoordinator.setAutoRefreshEnabled($0) }
            ))

            Picker("Interval", selection: Binding(
                get: { model.appSettings.autoRefreshInterval },
                set: { model.refreshCoordinator.setAutoRefreshInterval($0) }
            )) {
                ForEach(AppSettings.availableIntervals, id: \.self) { interval in
                    Text(Self.intervalLabel(interval)).tag(interval)
                }
            }
            .disabled(!model.appSettings.autoRefreshEnabled)
        }
    }

    private static func intervalLabel(_ interval: TimeInterval) -> String {
        switch interval {
        case 300: "5 minutes"
        case 1800: "30 minutes"
        case 3600: "1 hour"
        default: "\(Int(interval))s"
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Self.versionLabel)
        }
    }

    /// Version + build, read from the bundle so it always matches the release.
    static var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "unknown"
        guard let build = info?["CFBundleVersion"] as? String else { return version }
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView(model: AppModel())
}
