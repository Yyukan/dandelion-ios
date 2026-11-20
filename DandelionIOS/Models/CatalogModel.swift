//
//  CatalogModel.swift
//  Dandelion
//
//  Provider-agnostic catalog contracts, populated by ModelCatalogService from
//  OpenCode's `/zen/v1/models` and `/zen/go/v1/models` endpoints, which carry
//  each model's name, limits, prices and (Go) monthly allowance.
//

import Foundation

/// Pricing for a model, as published by OpenCode's model endpoints.
///
/// Text prices are per 1M tokens. Every value is optional: `nil` means the
/// endpoint publishes no such price for that model, which is different from
/// `0` ("Free").
struct ModelPricing: Codable, Sendable, Hashable {
    let inputPerM: Double?
    let outputPerM: Double?
    let cacheReadPerM: Double?
    let cacheWritePerM: Double?
    /// Higher price tier above a context size, where the model has one.
    let longContext: LongContextPricing?
    /// Non-text models (audio/image) priced per unit instead of per token.
    let unitPrice: UnitPrice?

    /// The endpoint lists the model without any `cost`.
    static let unpublished = ModelPricing(
        inputPerM: nil, outputPerM: nil, cacheReadPerM: nil, cacheWritePerM: nil,
        longContext: nil, unitPrice: nil
    )

    var isFree: Bool { inputPerM == 0 && (outputPerM ?? 0) == 0 }
    var isPublished: Bool { inputPerM != nil || outputPerM != nil || unitPrice != nil }
}

/// The per-1M-token price that applies once the context exceeds `aboveTokens`.
struct LongContextPricing: Codable, Sendable, Hashable {
    let aboveTokens: Int
    let inputPerM: Double?
    let outputPerM: Double?
}

/// A flat price per unit, e.g. `$0.05` per `minute` of audio or per `image`.
struct UnitPrice: Codable, Sendable, Hashable {
    let price: Double
    let unit: String
}

/// A Go model's monthly usage allowance in dollars, per Go plan, from the
/// endpoint's `go.monthly_usage`. OpenCode derives the shorter windows from
/// it: the 5-hour limit is 20% and the weekly limit 50% of the monthly one.
struct GoMonthlyAllowance: Codable, Sendable, Hashable {
    let go: Double?
    let goPlus: Double?
    let goTeams: Double?
}

/// Input/output modalities, as the endpoint names them (`"text"`, `"image/png"`, …).
struct ModelModalities: Codable, Sendable, Hashable {
    let input: [String]
    let output: [String]
}

/// Which OpenCode surface a catalog model belongs to.
enum CatalogProvider: String, Codable, Sendable, CaseIterable, Identifiable {
    case zen
    case go

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zen: "Zen"
        case .go: "Go"
        }
    }
}

/// A single model available on Zen or Go. Models the endpoint lists without a
/// name or cost are still listed, with the model ID as the display name and
/// no price, rather than being hidden.
///
/// Note: `modelID` is not unique across providers on its own (several models,
/// e.g. `glm-5.2`, are offered by both Zen and Go), so `id` combines provider +
/// modelID to stay a stable `Identifiable` key for SwiftUI lists.
struct CatalogModel: Codable, Sendable, Hashable, Identifiable {
    let modelID: String
    let displayName: String
    let provider: CatalogProvider
    let pricing: ModelPricing
    /// Go-only monthly dollar allowance per plan; always `nil` for Zen.
    var goAllowance: GoMonthlyAllowance?
    var family: String?
    var description: String?
    var contextLimit: Int?
    var outputLimit: Int?
    var modalities: ModelModalities?
    /// Names of the capabilities the endpoint marks as supported.
    var capabilities: [String] = []
    var releaseDate: String?
    var openWeights: Bool?

    var id: String { "\(provider.rawValue):\(modelID)" }
}
