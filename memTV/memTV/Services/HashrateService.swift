//
//  HashrateService.swift
//  memTV
//
//  Created by Taymur Khumush on 12/5/25.
//

import Foundation

struct HashrateDataPoint: Codable, Identifiable {
    let timestamp: Int
    let avgHashrate: Double

    var id: Int { timestamp }
}

struct HashrateResponse: Codable {
    let hashrates: [HashrateDataPoint]
    let currentHashrate: Double
    let currentDifficulty: Double
}

class HashrateService: ObservableObject {
    @Published var hashrateData: HashrateResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiURL = "https://mempool.space/api/v1/mining/hashrate/3m"

    func fetchHashrateData() async {
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
            let hashrate = try JSONDecoder().decode(HashrateResponse.self, from: data)

            await MainActor.run {
                hashrateData = hashrate
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch hashrate data: \(error.localizedDescription)"
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
