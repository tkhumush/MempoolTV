//
//  MiningPoolsService.swift
//  memTV
//
//  Created by Taymur Khumush on 12/5/25.
//

import Foundation

struct MiningPool: Codable, Identifiable {
    let poolId: Int
    let name: String
    let link: String
    let blockCount: Int
    let rank: Int
    let emptyBlocks: Int
    let slug: String
    let avgMatchRate: Double?
    let avgFeeDelta: String?
    let poolUniqueId: Int

    var id: Int { poolId }
}

struct MiningPoolsResponse: Codable {
    let pools: [MiningPool]
    let blockCount: Int
    let lastEstimatedHashrate: Double
    let lastEstimatedHashrate3d: Double?
    let lastEstimatedHashrate1w: Double?
}

class MiningPoolsService: ObservableObject {
    @Published var poolsData: MiningPoolsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiURL = "https://mempool.space/api/v1/mining/pools/1w"

    func fetchMiningPools() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            guard let url = URL(string: apiURL) else {
                await MainActor.run {
                    errorMessage = "Invalid URL"
                    isLoading = false
                }
                return
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let pools = try JSONDecoder().decode(MiningPoolsResponse.self, from: data)

            await MainActor.run {
                poolsData = pools
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch mining pools: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    // Helper to format hashrate in readable units (EH/s)
    func formatHashrate(_ hashrate: Double) -> String {
        let exahash = hashrate / 1_000_000_000_000_000_000 // Convert to EH/s
        return String(format: "%.2f EH/s", exahash)
    }
}
