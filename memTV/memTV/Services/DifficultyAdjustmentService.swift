//
//  DifficultyAdjustmentService.swift
//  memTV
//
//  Created by Taymur Khumush on 12/5/25.
//

import Foundation

struct DifficultyAdjustment: Codable {
    let progressPercent: Double
    let difficultyChange: Double
    let estimatedRetargetDate: Int
    let remainingBlocks: Int
    let remainingTime: Int
    let previousRetarget: Double
    let previousTime: Int
    let nextRetargetHeight: Int
    let timeAvg: Double
    let adjustedTimeAvg: Double?
    let timeOffset: Double
    let expectedBlocks: Double
}

class DifficultyAdjustmentService: ObservableObject {
    @Published var difficultyData: DifficultyAdjustment?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiURL = "https://mempool.space/api/v1/difficulty-adjustment"

    func fetchDifficultyAdjustment() async {
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
            let adjustment = try JSONDecoder().decode(DifficultyAdjustment.self, from: data)

            await MainActor.run {
                difficultyData = adjustment
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch difficulty adjustment: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    // Helper to format time remaining (divide by 1000 to fix decimal issue)
    func formatTimeRemaining(_ seconds: Int) -> String {
        let correctedSeconds = Double(seconds) / 1000.0
        let days = correctedSeconds / 86400.0

        return String(format: "%.1fd", days)
    }

    // Helper to format average block time (divide by 1000 to fix decimal issue)
    func formatAvgBlockTime(_ seconds: Double) -> String {
        let correctedSeconds = seconds / 1000.0
        let minutes = correctedSeconds / 60.0

        return String(format: "%.1fm", minutes)
    }
}
