//
//  NetworkStatsViewModel.swift
//  memTV
//
//  Aggregated state management for network statistics widgets.
//

import Foundation

@MainActor
final class NetworkStatsViewModel: ObservableObject {
    @Published var hashrateState: LoadableState<HashrateResponse> = .idle
    @Published var poolsState: LoadableState<MiningPoolsResponse> = .idle
    @Published var difficultyState: LoadableState<DifficultyAdjustment> = .idle
    @Published var priceState: LoadableState<PriceResponse> = .idle
    @Published var feesState: LoadableState<FeeEstimate> = .idle

    var hashrateData: HashrateResponse? { hashrateState.value }
    var poolsData: MiningPoolsResponse? { poolsState.value }
    var difficultyData: DifficultyAdjustment? { difficultyState.value }
    var priceResponse: PriceResponse? { priceState.value }
    var feeEstimate: FeeEstimate? { feesState.value }

    private let networkClient: NetworkClient
    private let hashrateURL = "https://mempool.space/api/v1/mining/hashrate/3m"
    private let poolsURL = "https://mempool.space/api/v1/mining/pools/1w"
    private let difficultyURL = "https://mempool.space/api/v1/difficulty-adjustment"
    private let priceURL = "https://mempool.space/api/v1/prices"
    private let feesURL = "https://mempool.space/api/v1/fees/precise"
    private var refreshTask: Task<Void, Never>?

    init(networkClient: NetworkClient = URLSessionNetworkClient()) {
        self.networkClient = networkClient
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTask = Task {
            await refreshAll()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(300 * 1_000_000_000)) // 5 minutes
                guard !Task.isCancelled else { break }
                await refreshAll()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refreshAll() async {
        async let hashrate: () = loadHashrate()
        async let pools: () = loadPools()
        async let difficulty: () = loadDifficulty()
        async let price: () = loadPrice()
        async let fees: () = loadFees()

        await hashrate
        await pools
        await difficulty
        await price
        await fees
    }

    private func loadHashrate() async {
        hashrateState = .loading
        do {
            let url = try url(for: hashrateURL)
            let response: HashrateResponse = try await networkClient.fetch(HashrateResponse.self, from: url)
            hashrateState = .loaded(response)
        } catch {
            hashrateState = .failed("Failed to fetch hashrate: \(error.localizedDescription)")
        }
    }

    private func loadPools() async {
        poolsState = .loading
        do {
            let url = try url(for: poolsURL)
            let response: MiningPoolsResponse = try await networkClient.fetch(MiningPoolsResponse.self, from: url)
            poolsState = .loaded(response)
        } catch {
            poolsState = .failed("Failed to fetch mining pools: \(error.localizedDescription)")
        }
    }

    private func loadDifficulty() async {
        difficultyState = .loading
        do {
            let url = try url(for: difficultyURL)
            let response: DifficultyAdjustment = try await networkClient.fetch(DifficultyAdjustment.self, from: url)
            difficultyState = .loaded(response)
        } catch {
            difficultyState = .failed("Failed to fetch difficulty: \(error.localizedDescription)")
        }
    }

    private func loadPrice() async {
        priceState = .loading
        do {
            let url = try url(for: priceURL)
            let response: PriceResponse = try await networkClient.fetch(PriceResponse.self, from: url)
            priceState = .loaded(response)
        } catch {
            priceState = .failed("Failed to fetch price: \(error.localizedDescription)")
        }
    }

    private func loadFees() async {
        feesState = .loading
        do {
            let url = try url(for: feesURL)
            let response: FeeEstimate = try await networkClient.fetch(FeeEstimate.self, from: url)
            feesState = .loaded(response)
        } catch {
            feesState = .failed("Failed to fetch fees: \(error.localizedDescription)")
        }
    }

    private func url(for string: String) throws -> URL {
        guard let url = URL(string: string) else {
            throw NetworkError.invalidURL
        }
        return url
    }

    deinit {
        stopAutoRefresh()
    }
}
