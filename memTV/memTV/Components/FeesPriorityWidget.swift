//
//  FeesPriorityWidget.swift
//  memTV
//
//  Created by Taymur Khumush on 9/23/25.
//

import SwiftUI

struct FeesPriorityWidget: View {
    @StateObject private var feeService = MempoolFeeService()
    @StateObject private var priceService = BitcoinPriceService()

    var body: some View {
        VStack(spacing: 8) {
            // Fee displays
            HStack(spacing: 1) {
                feeDisplay("Low", satPerVB: feeService.feeEstimate?.hourFee ?? 0)
                feeDisplay("Median", satPerVB: feeService.feeEstimate?.halfHourFee ?? 0)
                feeDisplay("High", satPerVB: feeService.feeEstimate?.fastestFee ?? 0)
            }
        }
        .onAppear {
            Task {
                await feeService.fetchFeeEstimates()
                await priceService.fetchPrice()
            }
        }
    }

    private func feeDisplay(_ priority: String, satPerVB: Int) -> some View {
        VStack(spacing: 4) {
            Text(priority)
                .font(.caption2)
                .foregroundColor(.white)

            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)

            VStack(spacing: 2) {
                Text("\(satPerVB) sat/vB")
                    .font(.caption2)
                    .foregroundColor(.white)

                Text(formatDollarValue(satPerVB: satPerVB))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private func formatDollarValue(satPerVB: Int) -> String {
        guard let btcPrice = priceService.currentPrice, btcPrice > 0 else {
            return "$0.00"
        }

        // Convert sat/vB to USD
        // 1 BTC = 100,000,000 sats
        let btcPerSat = Double(btcPrice) / 100_000_000.0
        let usdPerSatVB = Double(satPerVB) * btcPerSat

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3

        return formatter.string(from: NSNumber(value: usdPerSatVB)) ?? "$0.000"
    }
}


#Preview {
    FeesPriorityWidget()
        .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}
