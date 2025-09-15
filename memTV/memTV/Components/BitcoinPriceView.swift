//
//  BitcoinPriceView.swift
//  memTV
//
//  Created by Taymur Khumush on 9/15/25.
//

import SwiftUI

struct BitcoinPriceView: View {
    @StateObject private var priceService = BitcoinPriceService()

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("BTC")
                .font(.caption)
                .foregroundColor(.white)

            if priceService.isLoading {
                Text("Loading...")
                    .font(.title3)
                    .foregroundColor(.white)
            } else if let _ = priceService.errorMessage {
                Text("$--,---")
                    .font(.title3)
                    .foregroundColor(.red)
            } else {
                Text(priceService.formattedPrice())
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
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
