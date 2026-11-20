//
//  ModelCatalogView.swift
//  Dandelion
//
//  Full, searchable Zen + Go model catalog: per-model input/output pricing
//  plus the Go-only 5h/weekly/monthly dollar limits. There's no
//  disconnected-state gate
//  here - the catalog needs no local API key, so it always loads. Split into
//  two independent views: ModelCatalogControls (static) and ModelCatalogList,
//  which owns its own bounded ScrollView (mirroring the macOS status-bar
//  app's catalogList) so scrolling never escapes into the rest of the
//  dashboard - DashboardView's outer layout is a plain, non-scrolling VStack.
//

import SwiftUI
import UIKit

/// Search field + provider/sort pickers. No title - it's self-evident from
/// context. Meant to be pinned (non-scrolling) above `ModelCatalogList`.
struct ModelCatalogControls: View {
    @Bindable var viewModel: ModelCatalogViewModel

    var body: some View {
        VStack(spacing: TerminalTheme.Spacing.xs) {
            HStack(spacing: TerminalTheme.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundStyle(TerminalTheme.Colors.textTertiary)
                TextField("Search models…", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(TerminalTheme.Fonts.body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if viewModel.isLoadingCatalog {
                    ProgressView().controlSize(.mini)
                }
            }
            .padding(.horizontal, TerminalTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background(TerminalTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                Picker("Provider", selection: $viewModel.providerFilter) {
                    ForEach(CatalogProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Spacer()

                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(viewModel.availableSortOptions) { option in
                        Text(option.shortLabel).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .font(TerminalTheme.Fonts.body.weight(.semibold))
                .labelsHidden()
                .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The scrollable model list itself. Owns its own contained `ScrollView`
/// (plus pull-to-refresh and `loadInitial()`) so scrolling stays confined to
/// just the rows - nothing above or below it in DashboardView ever moves.
struct ModelCatalogList: View {
    let viewModel: ModelCatalogViewModel
    var onRefresh: () async -> Void = {}

    var body: some View {
        ScrollView {
            LazyVStack(spacing: TerminalTheme.Spacing.xs) {
                if viewModel.filteredModels.isEmpty {
                    Text(viewModel.isLoadingCatalog ? "Loading catalog…" : "No models match your search.")
                        .font(TerminalTheme.Fonts.caption)
                        .foregroundStyle(TerminalTheme.Colors.textTertiary)
                        .padding(.vertical, TerminalTheme.Spacing.md)
                } else {
                    ForEach(viewModel.filteredModels) { model in
                        CatalogModelRow(model: model)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .refreshable { await onRefresh() }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .task { await viewModel.loadInitial() }
    }
}

/// A single catalog row: vendor icon, name, colorized in/out pricing, and
/// (Go only) the 5h/weekly/monthly limit chips. The model ID is never shown -
/// it's the tap-to-copy target instead, confirmed by a brief border flash.
private struct CatalogModelRow: View {
    let model: CatalogModel

    @State private var justCopied = false

    var body: some View {
        HStack(spacing: TerminalTheme.Spacing.sm) {
            vendorIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(model.displayName)
                    .font(TerminalTheme.Fonts.body.weight(.semibold))
                    .lineLimit(1)
                if model.provider == .go {
                    goLimitsRow
                }
            }
            // The name column must win the space before the trailing price
            // does; without this, SwiftUI truncates names like
            // "DeepSeek V4 Flash" even when the row has room to spare.
            .layoutPriority(1)
            Spacer(minLength: TerminalTheme.Spacing.sm)
            priceStack
                .fixedSize()
        }
        .padding(TerminalTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TerminalTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TerminalTheme.Colors.accent, lineWidth: justCopied ? 1.5 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: copyModelID)
    }

    private var vendorIcon: some View {
        Group {
            if let asset = ModelVendor.assetName(forModelID: model.modelID) {
                Image(asset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: ModelVendor.fallbackSystemImage)
                    .foregroundStyle(TerminalTheme.Colors.textTertiary)
            }
        }
        .frame(width: 20, height: 20)
    }

    /// Input/output on one line, "/"-separated, each independently colored -
    /// more compact than stacking them, and the slash reads like a ratio.
    private var priceStack: some View {
        Group {
            if let unitPrice = model.pricing.unitPrice {
                // Audio/image models are priced per minute/image, not per token.
                Text(Self.unitPrice(unitPrice))
                    .foregroundStyle(Self.priceColor(unitPrice.price, max: Self.maxInputPrice(model.provider)))
            } else if !model.pricing.isPublished {
                // The endpoint lists the model without any cost.
                Text("—")
                    .foregroundStyle(TerminalTheme.Colors.textTertiary)
            } else if model.pricing.isFree {
                Text("Free")
                    .foregroundStyle(TerminalTheme.Colors.textTertiary)
            } else {
                HStack(spacing: 2) {
                    Text(Self.simplePrice(model.pricing.inputPerM))
                        .foregroundStyle(Self.priceColor(model.pricing.inputPerM, max: Self.maxInputPrice(model.provider)))
                    Text("/")
                        .foregroundStyle(TerminalTheme.Colors.textTertiary)
                    Text(Self.simplePrice(model.pricing.outputPerM))
                        .foregroundStyle(Self.priceColor(model.pricing.outputPerM, max: Self.maxOutputPrice(model.provider)))
                }
            }
        }
        .font(TerminalTheme.Fonts.caption)
    }

    /// Go-only, one line: the three limit chips, exactly as OpenCode documents
    /// them - the 5-hour limit is 20% of the monthly allowance, the weekly
    /// limit is 50% (resets Monday 00:00 UTC), the monthly limit is 100%.
    /// Free models never draw down the allowance, so they show "∞".
    private var goLimitsRow: some View {
        let monthly = model.goAllowance?.go
        let unlimited = model.pricing.isFree

        func value(_ fraction: Double) -> String {
            if unlimited { return "∞" }
            guard let monthly else { return "—" }
            return Self.money(monthly * fraction)
        }

        return HStack(spacing: 10) {
            limitChip("clock", value(0.20))
            limitChip("calendar", value(0.50))
            limitChip("dollarsign.circle", value(1))
        }
        .font(TerminalTheme.Fonts.caption)
    }

    private func limitChip(_ systemImage: String, _ value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
                .foregroundStyle(TerminalTheme.Colors.textTertiary)
            Text(value)
                .foregroundStyle(TerminalTheme.Colors.textSecondary)
        }
        .fixedSize()
    }

    /// Copies the (hidden) model ID to the clipboard and briefly flashes the
    /// row's border as the only copy confirmation.
    private func copyModelID() {
        UIPasteboard.general.string = model.modelID
        withAnimation(.easeOut(duration: 0.15)) { justCopied = true }
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeOut(duration: 0.3)) { justCopied = false }
        }
    }

    // MARK: Formatting

    /// Per-provider price ceilings used to normalize the log-scale color -
    /// Go's real catalog tops out far below Zen's ($3/$15 vs $30/$180), so
    /// sharing one ceiling would paint the entire Go tab a uniform cyan.
    private static func maxInputPrice(_ provider: CatalogProvider) -> Double {
        provider == .zen ? 30 : 3
    }

    private static func maxOutputPrice(_ provider: CatalogProvider) -> Double {
        provider == .zen ? 180 : 15
    }

    private static func simplePrice(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "$" + String(format: "%.2f", value)
    }

    /// "$0.05/min", "$0.01/image".
    private static func unitPrice(_ unitPrice: UnitPrice) -> String {
        let unit = unitPrice.unit == "minute" ? "min" : unitPrice.unit
        return simplePrice(unitPrice.price) + "/" + unit
    }

    /// Whole dollars without cents ("$100"), otherwise two decimals.
    private static func money(_ value: Double) -> String {
        value == value.rounded() ? String(format: "$%.0f", value) : simplePrice(value)
    }

    /// Colors a price on a log scale within the app's blue accent family
    /// (cyan for cheap, indigo for pricey) instead of a green-to-red scheme,
    /// so pricier models read as "hotter blue" rather than alarming.
    private static func priceColor(_ value: Double?, max: Double) -> Color {
        guard let value, value > 0 else { return TerminalTheme.Colors.textTertiary }
        return blueGradient(min(1, log10(value + 1) / log10(max + 1)))
    }

    private static func blueGradient(_ t: Double) -> Color {
        Color(hue: 0.52 + 0.18 * t, saturation: 0.45 + 0.30 * t, brightness: 0.95 - 0.10 * t)
    }
}

#Preview {
    let viewModel = ModelCatalogViewModel()
    VStack(alignment: .leading, spacing: TerminalTheme.Spacing.sm) {
        ModelCatalogControls(viewModel: viewModel)
        ModelCatalogList(viewModel: viewModel)
    }
    .frame(height: 400)
    .padding()
    .background(TerminalTheme.Colors.background)
}
