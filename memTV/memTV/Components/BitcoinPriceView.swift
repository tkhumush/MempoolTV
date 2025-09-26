//
//  BitcoinPriceView.swift
//  memTV
//
//  Created by Taymur Khumush on 9/15/25.
//

import SwiftUI

struct BitcoinPriceView: View {
    @StateObject private var priceService = BitcoinPriceService()
    @State private var showSatsPerDollar = false

    var body: some View {
        Button {
            showSatsPerDollar.toggle()
        } label: {
            VStack(alignment: .trailing, spacing: 4) {
                Text(showSatsPerDollar ? "SATS/$" : "BTC")
                    .font(.caption)
                    .foregroundColor(.white)

                if priceService.isLoading {
                    Text("Loading...")
                        .font(.title3)
                        .foregroundColor(.white)
                } else if let _ = priceService.errorMessage {
                    Text(showSatsPerDollar ? "--,---" : "$--,---")
                        .font(.title3)
                        .foregroundColor(.red)
                } else {
                    Text(showSatsPerDollar ? priceService.formattedSatsPerDollar() : priceService.formattedPrice())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.appleTV)
        .onAppear {
            Task {
                await priceService.fetchPrice()
            }
        }
    }
}

#Preview {
    BitcoinPriceView()
        .background(Color.black)
}
