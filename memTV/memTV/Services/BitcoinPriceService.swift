//
//  BitcoinPriceService.swift
//  memTV
//
//  Created by Taymur Khumush on 9/15/25.
//

import Foundation

struct PriceResponse: Codable {
    let time: Int
    let USD: Int
    let EUR: Int?
    let GBP: Int?
    let CAD: Int?
    let CHF: Int?
    let AUD: Int?
    let JPY: Int?
}

class BitcoinPriceService: ObservableObject {
    @Published var currentPrice: Int?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let priceURL = "https://mempool.space/api/v1/prices"

    func fetchPrice() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            guard let url = URL(string: priceURL) else {
                await MainActor.run {
                    errorMessage = "Invalid URL"
                    isLoading = false
                }
                return
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let priceResponse = try JSONDecoder().decode(PriceResponse.self, from: data)

            await MainActor.run {
                currentPrice = priceResponse.USD
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch price: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func formattedPrice() -> String {
        guard let price = currentPrice else { return "$--,---" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        if let formattedNumber = formatter.string(from: NSNumber(value: price)) {
            return "$\(formattedNumber)"
        }
        return "$\(price)"
    }
}