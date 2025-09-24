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
            // Priority segments pill
            HStack(spacing: 0) {
                prioritySegment("No Priority", isFirst: true, isLast: false)
                prioritySegment("Low Priority", isFirst: false, isLast: false)
                prioritySegment("Medium Priority", isFirst: false, isLast: false)
                prioritySegment("High Priority", isFirst: false, isLast: true)
            }
            .frame(height: 30)

            // Fee displays
            HStack(spacing: 20) {
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

    private func prioritySegment(_ text: String, isFirst: Bool, isLast: Bool) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.7))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: isFirst ? 15 : 0,
                    bottomLeadingRadius: isFirst ? 15 : 0,
                    bottomTrailingRadius: isLast ? 15 : 0,
                    topTrailingRadius: isLast ? 15 : 0
                )
            )
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
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: usdPerSatVB)) ?? "$0.00"
    }
}


#Preview {
    FeesPriorityWidget()
        .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}