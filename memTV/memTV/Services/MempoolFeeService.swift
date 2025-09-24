//
//  MempoolFeeService.swift
//  memTV
//
//  Created by Taymur Khumush on 9/23/25.
//

import Foundation

struct FeeEstimate: Codable {
    let fastestFee: Int
    let halfHourFee: Int
    let hourFee: Int
    let economyFee: Int
    let minimumFee: Int
}

class MempoolFeeService: ObservableObject {
    @Published var feeEstimate: FeeEstimate?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let feeURL = "https://mempool.space/api/v1/fees/recommended"

    func fetchFeeEstimates() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            guard let url = URL(string: feeURL) else {
                await MainActor.run {
                    errorMessage = "Invalid URL"
                    isLoading = false
                }
                return
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let estimate = try JSONDecoder().decode(FeeEstimate.self, from: data)

            await MainActor.run {
                feeEstimate = estimate
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch fee estimates: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}