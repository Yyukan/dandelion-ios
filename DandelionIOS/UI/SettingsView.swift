//
//  SettingsView.swift
//  Dandelion
//
//  OpenCode sign-in status + auto-refresh interval picker. iOS has no local
//  auth.json or browser cookie jar to auto-discover, so signing in is a
//  first-class, user-initiated action here (see SessionAuthService).
//

import SwiftUI

struct SettingsView: View {
    let model: AppModel

    @Environment(\.dismiss) private var dismiss
    @State private var showSignIn = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                refreshSection
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
                Text("Sign in to see your live Zen balance and Go usage.")
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
            }

            Button(model.authService.isSignedIn ? "Sign In Again" : "Sign In") {
                showSignIn = true
            }
        }
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
}

#Preview {
    SettingsView(model: AppModel())
}
