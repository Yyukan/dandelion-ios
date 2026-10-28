//
//  SettingsView.swift
//  Dandelion
//
//  The OpenCode API key and the auto-refresh interval picker. One key covers
//  both surfaces the app shows - the console's billing API (Zen balance) and
//  Go usage - and it is stored in the Keychain (see APIKeyStore). There is no
//  sign-in flow: iOS has no access to OpenCode's local auth.json or a browser
//  cookie jar, and neither is needed any more.
//

import SwiftUI

struct SettingsView: View {
    let model: AppModel

    @State private var apiKey = ""
    /// First characters of the stored key, so it's obvious one is saved;
    /// `nil` when no key is stored, in which case nothing is shown.
    @State private var storedKeyPrefix: String?
    @FocusState private var keyFieldFocused: Bool

    private let apiKeyStore = APIKeyStore()

    var body: some View {
        NavigationStack {
            Form {
                keySection
                refreshSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(TerminalTheme.Colors.background)
            .foregroundStyle(TerminalTheme.Colors.textPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task { refreshStoredKey() }
        }
    }

    private var keySection: some View {
        Section("OpenCode API key") {
            if let storedKeyPrefix {
                LabeledContent("Saved key", value: "\(storedKeyPrefix)…")
                Button("Remove Key", role: .destructive, action: removeAPIKey)
            }

            SecureField(storedKeyPrefix == nil ? "API key" : "Replace key", text: $apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($keyFieldFocused)
                .submitLabel(.done)
                .onSubmit(saveAPIKey)
                // Save on focus loss as well, so a key typed but never
                // submitted isn't silently dropped when the sheet closes.
                .onChange(of: keyFieldFocused) { _, isFocused in
                    if !isFocused { saveAPIKey() }
                }

            Text("One key powers both cards: it reads your Zen balance and your Go usage. Create it in the OpenCode console, then paste it here.")
                .font(TerminalTheme.Fonts.caption)
                .foregroundStyle(TerminalTheme.Colors.textSecondary)

            Link("OpenCode console", destination: URL(string: "https://opencode.ai/console")!)
                .font(TerminalTheme.Fonts.caption)
        }
    }

    private func saveAPIKey() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        apiKeyStore.save(key)
        apiKey = ""
        refreshStoredKey()
        Task { await model.refreshCoordinator.refreshNow() }
    }

    private func removeAPIKey() {
        apiKeyStore.clear()
        refreshStoredKey()
        Task { await model.refreshCoordinator.refreshNow() }
    }

    /// Mirrors the keychain into `storedKeyPrefix` - first 10 characters only,
    /// never the whole key.
    private func refreshStoredKey() {
        storedKeyPrefix = apiKeyStore.load().map { String($0.prefix(10)) }
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
