//
//  BitcoinPriceView.swift
//  memTV
//
//  BTC price display driven by a shared ViewModel.
//

import SwiftUI

struct BitcoinPriceView: View {
    let priceResponse: PriceResponse?
    @State private var showSatsPerDollar = false

    var body: some View {
        Button {
            showSatsPerDollar.toggle()
        } label: {
            VStack(alignment: .trailing, spacing: 4) {
                Text(showSatsPerDollar ? "SATS/$" : "BTC")
                    .font(.caption)
                    .foregroundColor(.white)

                if let response = priceResponse {
                    Text(showSatsPerDollar ? formattedSatsPerDollar(response.USD) : formattedPrice(response.USD))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                } else {
                    Text(showSatsPerDollar ? "--,---" : "$--,---")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
        }
        .buttonStyle(.appleTV)
    }

    private func formattedPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        if let formattedNumber = formatter.string(from: NSNumber(value: price)) {
            return "$\(formattedNumber)"
        }
        return "$\(price)"
    }

    private func formattedSatsPerDollar(_ price: Int) -> String {
        guard price > 0 else { return "--,---" }
        let satsPerDollar = 100_000_000 / price

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSNumber(value: satsPerDollar)) ?? "\(satsPerDollar)"
    }
}

#Preview {
    BitcoinPriceView(priceResponse: PriceResponse(time: 0, USD: 65_000, EUR: nil, GBP: nil, CAD: nil, CHF: nil, AUD: nil, JPY: nil))
        .background(Color.black)
}
