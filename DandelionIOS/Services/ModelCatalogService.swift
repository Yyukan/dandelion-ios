//
//  ModelCatalogService.swift
//  Dandelion
//
//  Builds the Zen/Go model catalog from OpenCode's model endpoints only:
//
//    https://opencode.ai/zen/v1/models     -> Zen models
//    https://opencode.ai/zen/go/v1/models  -> Go models (+ `go.monthly_usage`)
//
//  Each entry carries the model's name, limits, text/cache prices (with any
//  long-context override), audio/image unit prices and, on Go, the monthly
//  dollar allowance per plan. No docs page is fetched or parsed.
//
//  Cached locally for 24h, falling back to the last successful catalog when a
//  fetch or decode fails, so an endpoint outage never empties the view.
//

import Foundation

/// Fetches, decodes and caches OpenCode's Zen/Go catalog into `CatalogModel`.
actor ModelCatalogService {
    private static let zenModelsURL = URL(string: "https://opencode.ai/zen/v1/models")!
    private static let goModelsURL = URL(string: "https://opencode.ai/zen/go/v1/models")!

    private static let refreshInterval: TimeInterval = 24 * 60 * 60 // daily cadence
    /// Bumped whenever `CatalogModel`'s shape or meaning changes, so a cache
    /// written by an older build is refetched instead of misread.
    private static let cacheFormatVersion = 2

    private let session: URLSession
    private let cacheFileURL: URL
    /// Pre-migration caches (models.dev catalog + separate Go limits table).
    private let legacyCacheFileURLs: [URL]

    init(session: URLSession = .shared, fileManager: FileManager = .default) {
        self.session = session

        let cacheDirectory = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Dandelion", isDirectory: true))
            ?? fileManager.temporaryDirectory.appendingPathComponent("Dandelion", isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        self.cacheFileURL = cacheDirectory.appendingPathComponent("catalog-cache.json")
        self.legacyCacheFileURLs = ["model-catalog-cache.json", "go-usage-limits-cache.json"]
            .map { cacheDirectory.appendingPathComponent($0) }
    }

    /// Returns the Zen + Go catalog, preferring a fresh local cache (younger
    /// than 24h) unless `forceRefresh` is set. Falls back to the last
    /// successful cache when a fetch or decode fails.
    func loadCatalog(forceRefresh: Bool = false) async -> [CatalogModel] {
        let cached = readCache()

        if !forceRefresh, let cached, Date().timeIntervalSince(cached.fetchedAt) < Self.refreshInterval {
            return cached.models
        }

        do {
            let models = try await fetchCatalog()
            writeCache(CachedCatalog(formatVersion: Self.cacheFormatVersion, fetchedAt: Date(), models: models))
            removeLegacyCaches()
            return models
        } catch {
            return cached?.models ?? []
        }
    }

    // MARK: Remote fetch

    private func fetchCatalog() async throws -> [CatalogModel] {
        async let zenModels = fetchModels(from: Self.zenModelsURL, provider: .zen)
        async let goModels = fetchModels(from: Self.goModelsURL, provider: .go)
        let (zen, go) = try await (zenModels, goModels)
        guard !zen.isEmpty, !go.isEmpty else { throw URLError(.cannotParseResponse) }

        return (zen + go).sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    private func fetchModels(from url: URL, provider: CatalogProvider) async throws -> [CatalogModel] {
        let data = try await get(url)
        return try JSONDecoder().decode(ModelListResponse.self, from: data).data
            .compactMap { $0.value?.catalogModel(provider: provider) }
    }

    private func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("Mozilla/5.0 (Dandelion)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: Endpoint payload

    private struct ModelListResponse: Decodable {
        let data: [Lossy<ModelEntry>]
    }

    /// Decodes one element, or `nil` if it doesn't fit - one odd model must not
    /// empty the whole list.
    private struct Lossy<Value: Decodable>: Decodable {
        let value: Value?

        init(from decoder: Decoder) throws {
            value = try? Value(from: decoder)
        }
    }

    private struct ModelEntry: Decodable {
        let id: String
        let name: String?
        let family: String?
        let description: String?
        let releaseDate: String?
        let openWeights: Bool?
        let modalities: Modalities?
        let capabilities: Capabilities?
        let limit: Limit?
        let cost: Cost?
        let go: GoInfo?

        enum CodingKeys: String, CodingKey {
            case id, name, family, description, modalities, capabilities, limit, cost, go
            case releaseDate = "release_date"
            case openWeights = "open_weights"
        }

        func catalogModel(provider: CatalogProvider) -> CatalogModel {
            CatalogModel(
                modelID: id,
                displayName: name ?? id,
                provider: provider,
                pricing: cost?.pricing ?? .unpublished,
                goAllowance: provider == .go ? go?.monthlyUsage?.allowance : nil,
                family: family,
                description: description,
                contextLimit: limit?.context,
                outputLimit: limit?.output,
                modalities: modalities.map {
                    ModelModalities(input: $0.input ?? [], output: $0.output ?? [])
                },
                capabilities: capabilities?.supported ?? [],
                releaseDate: releaseDate,
                openWeights: openWeights
            )
        }
    }

    private struct Modalities: Decodable {
        let input: [String]?
        let output: [String]?
    }

    /// Capabilities come either as a bare flag (`"structured_output": true`)
    /// or as an object (`"tools": {"supported": true}`); keeps the names of
    /// those marked supported.
    private struct Capabilities: Decodable {
        let supported: [String]

        private struct Key: CodingKey {
            let stringValue: String
            var intValue: Int? { nil }
            init(stringValue: String) { self.stringValue = stringValue }
            init?(intValue: Int) { nil }
        }

        private struct Flag: Decodable {
            let supported: Bool?
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Key.self)
            supported = container.allKeys.filter { key in
                if let flag = try? container.decode(Bool.self, forKey: key) { return flag }
                return (try? container.decode(Flag.self, forKey: key))?.supported == true
            }
            .map(\.stringValue)
            .sorted()
        }
    }

    private struct Limit: Decodable {
        let context: Int?
        let output: Int?
    }

    private struct Cost: Decodable {
        let text: Media?
        let audio: Media?
        let image: Media?

        var pricing: ModelPricing {
            ModelPricing(
                inputPerM: text?.input?.price,
                outputPerM: text?.output?.price,
                cacheReadPerM: text?.input?.cache?.read,
                cacheWritePerM: text?.input?.cache?.write,
                longContext: text?.longContext,
                unitPrice: text == nil ? (audio?.unitPrice ?? image?.unitPrice) : nil
            )
        }
    }

    private struct Media: Decodable {
        let input: Rate?
        let output: Rate?

        /// The first context-size override, joined across input and output.
        var longContext: LongContextPricing? {
            let threshold = input?.contextThreshold ?? output?.contextThreshold
            guard let threshold else { return nil }
            let inputPrice = input?.override(above: threshold)?.price
            let outputPrice = output?.override(above: threshold)?.price
            guard inputPrice != nil || outputPrice != nil else { return nil }
            return LongContextPricing(aboveTokens: threshold, inputPerM: inputPrice, outputPerM: outputPrice)
        }

        var unitPrice: UnitPrice? {
            for rate in [input, output] {
                if let price = rate?.price, let unit = rate?.unit {
                    return UnitPrice(price: price, unit: unit)
                }
            }
            return nil
        }
    }

    private struct Rate: Decodable {
        let price: Double?
        let unit: String?
        let cache: Cache?
        let overrides: [Lossy<Override>]?

        var contextThreshold: Int? {
            overrides?.lazy.compactMap { $0.value?.when?.context?.gt }.first
        }

        func override(above threshold: Int) -> Override? {
            overrides?.lazy.compactMap(\.value).first { $0.when?.context?.gt == threshold }
        }
    }

    /// Cache prices. `read` is always a flat number, but `write` is either a
    /// flat number or an object keyed by retention window
    /// (`{"30m": 0.125, "12h": 0.25}`, `{"5m": 1.875, "1h": 3}`). Models that
    /// use the tiered form must not be dropped: decode either shape and keep
    /// the shortest-retention price (the lowest one), which is what a default
    /// request actually pays.
    private struct Cache: Decodable {
        let read: Double?
        let write: Double?

        private enum CodingKeys: String, CodingKey {
            case read, write
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            read = Self.number(container, forKey: .read)
            write = Self.number(container, forKey: .write)
        }

        private static func number(
            _ container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) -> Double? {
            if let flat = try? container.decodeIfPresent(Double.self, forKey: key) {
                return flat
            }
            if let tiers = try? container.decodeIfPresent([String: Double].self, forKey: key) {
                return tiers.values.min()
            }
            return nil
        }
    }

    private struct Override: Decodable {
        struct When: Decodable {
            struct Bound: Decodable {
                let gt: Int?
            }
            let context: Bound?
        }
        let when: When?
        let price: Double?
    }

    private struct GoInfo: Decodable {
        struct MonthlyUsage: Decodable {
            let go: Double?
            let goPlus: Double?
            let goTeams: Double?

            enum CodingKeys: String, CodingKey {
                case go
                case goPlus = "go-plus"
                case goTeams = "go-teams"
            }

            var allowance: GoMonthlyAllowance? {
                guard go != nil || goPlus != nil || goTeams != nil else { return nil }
                return GoMonthlyAllowance(go: go, goPlus: goPlus, goTeams: goTeams)
            }
        }

        let monthlyUsage: MonthlyUsage?

        enum CodingKeys: String, CodingKey {
            case monthlyUsage = "monthly_usage"
        }
    }

    // MARK: Local disk cache

    private struct CachedCatalog: Codable {
        let formatVersion: Int
        let fetchedAt: Date
        let models: [CatalogModel]
    }

    private func readCache() -> CachedCatalog? {
        guard let data = try? Data(contentsOf: cacheFileURL),
              let cached = try? JSONDecoder().decode(CachedCatalog.self, from: data),
              cached.formatVersion == Self.cacheFormatVersion else { return nil }
        return cached
    }

    private func writeCache(_ catalog: CachedCatalog) {
        guard let data = try? JSONEncoder().encode(catalog) else { return }
        try? data.write(to: cacheFileURL, options: .atomic)
    }

    private func removeLegacyCaches() {
        for url in legacyCacheFileURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
