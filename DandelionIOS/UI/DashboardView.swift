//
//  DashboardView.swift
//  Dandelion
//
//  Root dashboard screen: a full-width scrolling layout with native
//  pull-to-refresh, showing Zen Balance, Go Usage, and Model Catalog in that
//  order. Settings has no dedicated toolbar entry point - tapping the Zen
//  Balance or Go Usage card opens it instead.
//

import SwiftUI

struct DashboardView: View {
    let model: AppModel

    @State private var showSettings = false
    @State private var showSignIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TerminalTheme.Spacing.md) {
                    CardContainer {
                        ZenBalanceCard(viewModel: model.zenBalanceViewModel, onSignIn: signIn)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showSettings = true }

                    CardContainer {
                        GoUsageCard(viewModel: model.goUsageViewModel, onSignIn: signIn)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showSettings = true }

                    CardContainer {
                        ModelCatalogView(viewModel: model.catalogViewModel)
                    }
                }
                .padding(TerminalTheme.Spacing.lg)
            }
            .background(TerminalTheme.Colors.background.ignoresSafeArea())
            .foregroundStyle(TerminalTheme.Colors.textPrimary)
            .refreshable { await model.refreshCoordinator.refreshNow() }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettings) {
                SettingsView(model: model)
            }
            .sheet(isPresented: $showSignIn) {
                SignInWebView(url: model.authService.signInURL) { cookieValue in
                    Task { await model.finishSignIn(cookieValue: cookieValue) }
                }
            }
        }
        .task { await model.refreshCoordinator.refreshNow() }
    }

    private func signIn() {
        showSignIn = true
    }
}

/// A dark card container used for each dashboard section; sections render
/// their own title (or none, like the model catalog), so this intentionally
/// has no fixed header of its own.
private struct CardContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(TerminalTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TerminalTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TerminalTheme.Metrics.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: TerminalTheme.Metrics.cardCornerRadius)
                    .stroke(TerminalTheme.Colors.border, lineWidth: 1)
            )
    }
}

#Preview {
    DashboardView(model: AppModel())
}
