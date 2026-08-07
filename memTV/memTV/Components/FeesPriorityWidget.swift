//
//  FeesPriorityWidget.swift
//  memTV
//
//  Header fee-priority widget driven by a shared ViewModel.
//

import SwiftUI

struct FeesPriorityWidget: View {
    let feeEstimate: FeeEstimate?
    let btcPrice: Int?

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 1) {
                feeDisplay("No Rush", satPerVB: feeEstimate?.minimumFee ?? 0)
                feeDisplay("Economy", satPerVB: feeEstimate?.economyFee ?? 0)
                feeDisplay("Standard", satPerVB: feeEstimate?.hourFee ?? 0)
                feeDisplay("Fast", satPerVB: feeEstimate?.halfHourFee ?? 0)
                feeDisplay("Fastest", satPerVB: feeEstimate?.fastestFee ?? 0)
            }
        }
    }

    private func feeDisplay(_ priority: String, satPerVB: Double) -> some View {
        VStack(spacing: 4) {
            Text(priority)
                .font(.caption2)
                .foregroundColor(.white)

            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)

            VStack(spacing: 2) {
                Text(String(format: "%.1f sat/vB", satPerVB))
                    .font(.caption2)
                    .foregroundColor(.white)

                Text(formatDollarValue(satPerVB: satPerVB))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private func formatDollarValue(satPerVB: Double) -> String {
        guard let btcPrice = btcPrice, btcPrice > 0 else {
            return "$0.00"
        }

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
    FeesPriorityWidget(
        feeEstimate: FeeEstimate(fastestFee: 50, halfHourFee: 35, hourFee: 25, economyFee: 15, minimumFee: 5),
        btcPrice: 65_000
    )
    .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}
