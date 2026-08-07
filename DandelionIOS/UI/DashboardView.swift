//
//  DashboardView.swift
//  Dandelion
//
//  Root dashboard screen: a static, non-scrolling outer layout (mirrors the
//  macOS status-bar app's DashboardPanel) - Zen Balance, Go Usage, and the
//  model catalog's search/filter controls never move. Only ModelCatalogList
//  carries its own contained ScrollView (with pull-to-refresh), so scrolling
//  is confined to just the model rows, never the whole pane. Settings has no
//  dedicated toolbar entry point - tapping the Zen Balance or Go Usage card
//  opens it instead.
//

import SwiftUI

struct DashboardView: View {
    let model: AppModel

    @State private var showSettings = false
    @State private var showSignIn = false

    var body: some View {
        NavigationStack {
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
                    VStack(alignment: .leading, spacing: TerminalTheme.Spacing.sm) {
                        ModelCatalogControls(viewModel: model.catalogViewModel)
                        ModelCatalogList(
                            viewModel: model.catalogViewModel,
                            onRefresh: model.refreshCoordinator.refreshNow
                        )
                    }
                }
            }
            .padding(TerminalTheme.Spacing.lg)
            .background(TerminalTheme.Colors.background.ignoresSafeArea())
            .foregroundStyle(TerminalTheme.Colors.textPrimary)
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
