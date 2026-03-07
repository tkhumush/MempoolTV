//
//  BlockDetailView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/31/25.
//

import SwiftUI

struct BlockDetailView: View {
    let selectedBlock: SelectedBlockType

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(blockTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                StatusBadge(isConfirmed: isConfirmed)
            }
            .padding(.bottom, 1)

            switch selectedBlock {
            case .confirmed(let block):
                ConfirmedBlockDetailView(block: block)
            case .mempool(let transaction):
                MempoolBlockDetailView(transaction: transaction)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }

    private var isConfirmed: Bool {
        if case .confirmed = selectedBlock { return true }
        return false
    }

    private var blockTitle: String {
        if case .confirmed = selectedBlock { return "Confirmed Block" }
        return "Mempool Block"
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let isConfirmed: Bool

    var body: some View {
        Text(isConfirmed ? "CONFIRMED" : "MEMPOOL")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isConfirmed ? Color.yellow : Color.purple)
            .foregroundColor(.black)
            .cornerRadius(15)
    }
}

struct DetailCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.gray)
                .fontWeight(.semibold)

            Text(value)
                .font(.title3)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MempoolDataTable: View {
    let transaction: MempoolTransaction

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            MempoolDataRow(label: "Median Fee", value: "~\(transaction.medianFee) sat/vB")
            MempoolDataRow(label: "Fee Span", value: feeSpanText)
            MempoolDataRow(label: "Total Fees", value: totalFeesText)
            MempoolDataRow(label: "Transactions", value: "\(transaction.nTx)")
            MempoolDataRow(label: "Block Size", value: blockSizeText)
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var feeSpanText: String {
        guard !transaction.feeRange.isEmpty else { return "N/A" }
        let min = transaction.feeRange.min() ?? 0
        let max = transaction.feeRange.max() ?? 0
        return String(format: "%.2f - %.1f sat/vB", min, max)
    }

    private var totalFeesText: String {
        let btc = Double(transaction.totalFees) / 100_000_000.0
        return String(format: "%.3f BTC", btc)
    }

    private var blockSizeText: String {
        let mb = Double(transaction.blockSize) / 1_000_000.0
        return String(format: "%.2f MB", mb)
    }
}

struct MempoolDataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    Group {
        BlockDetailView(selectedBlock: .confirmed(
            Block(
                hash: "0000000000000000000123456789abcdef",
                height: 800000,
                time: 1693478400,
                txCount: 2341,
                size: 1048576,
                weight: 3993216,
                totalFees: 0.1234,
                medianFee: 45.5,
                subsidy: 6.25,
                miner: "FoundryUSA"
            )
        ))

        BlockDetailView(selectedBlock: .mempool(
            MempoolTransaction(
                txid: "abc123def456ghi789jkl",
                fee: 12500,
                vsize: 250,
                position: 0,
                estimatedConfirmationTime: 10,
                medianFee: 45,
                blockSize: 1710000,
                blockVSize: 999500,
                nTx: 3752,
                totalFees: 10500000,
                feeRange: [0.29, 15.6, 32.1, 45.2, 67.8, 89.3, 153.2]
            )
        ))
    }
    .background(Color.black)
}
