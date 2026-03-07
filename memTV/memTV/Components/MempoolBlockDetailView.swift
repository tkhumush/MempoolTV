//
//  MempoolBlockDetailView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/31/25.
//

import SwiftUI

struct MempoolBlockDetailView: View {
    let transaction: MempoolTransaction

    var body: some View {
        HStack(alignment: .top, spacing: 50) {
            // Left side: Data table + Fee distribution chart
            VStack(alignment: .leading, spacing: 5) {
                Text("Block Statistics")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.bottom, 2)

                MempoolDataTable(transaction: transaction)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Block Fee Distribution")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Fee spread for this mempool block")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    FeeDistributionChart(feeData: generateFeeDistributionData(from: transaction))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side: Top transactions chart
            VStack(alignment: .leading, spacing: 5) {
                Text("Top 10 Largest Transactions")
                    .font(.subheadline)
                    .foregroundColor(.white)

                HStack {
                    TopTransactionsChart(transaction: transaction)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func generateFeeDistributionData(from transaction: MempoolTransaction) -> [FeeRange] {
        guard !transaction.feeRange.isEmpty else {
            let medianFee = Double(transaction.medianFee)
            return [FeeRange(
                minFee: Int(medianFee * 0.8),
                maxFee: Int(medianFee * 1.2),
                txCount: transaction.nTx
            )]
        }

        let sortedFees = transaction.feeRange.sorted()
        return sortedFees.map { feeRate in
            FeeRange(
                minFee: Int(feeRate * 1000),
                maxFee: Int(feeRate * 1000),
                txCount: 1
            )
        }
    }
}
