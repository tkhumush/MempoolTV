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
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                Text(blockTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                StatusBadge(isConfirmed: isConfirmed)
            }
            .padding(.bottom, 5)
            
            switch selectedBlock {
            case .confirmed(_):
                // Existing confirmed block layout
                confirmedBlockView
            case .mempool(let transaction):
                // New mempool block layout
                mempoolBlockView(transaction: transaction)
            }
            
            // Fee Distribution Chart (only for mempool transactions)
            if case .mempool(_) = selectedBlock {
                HStack {
                    FeeDistributionChart(feeData: mockFeeData)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
            
            Spacer()
        }
        .padding(30)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
    
    // MARK: - Confirmed Block View
    
    private var confirmedBlockView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), alignment: .leading, spacing: 20) {
            DetailCard(title: "Number", value: blockNumber)
            DetailCard(title: "Hash", value: hashValue)
            
            if let txCount = transactionCount {
                DetailCard(title: "Transactions", value: "\(txCount)")
            }
            
            if let timestamp = blockTimestamp {
                DetailCard(title: "Time", value: timestamp)
            }
        }
    }
    
    // MARK: - Mempool Block View
    
    private func mempoolBlockView(transaction: MempoolTransaction) -> some View {
        HStack(alignment: .top, spacing: 30) {
            // Left side: Data table
            VStack(alignment: .leading, spacing: 15) {
                Text("Block Statistics")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.bottom, 2)
                
                MempoolDataTable(transaction: transaction)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side: Transaction visualization
            VStack(alignment: .leading, spacing: 8) {
                Text("Transactions by Size")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        Text("Transaction Size\nVisualization\n(Coming Soon)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    )
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isConfirmed: Bool {
        switch selectedBlock {
        case .confirmed(_):
            return true
        case .mempool(_):
            return false
        }
    }
    
    private var blockTitle: String {
        switch selectedBlock {
        case .confirmed(_):
            return "Confirmed Block"
        case .mempool(_):
            return "Mempool Block"
        }
    }
    
    private var blockNumber: String {
        switch selectedBlock {
        case .confirmed(let block):
            return "\(block.height)"
        case .mempool(let transaction):
            return String(transaction.txid.prefix(8).hashValue % 100000)
        }
    }
    
    private var hashValue: String {
        switch selectedBlock {
        case .confirmed(let block):
            return String(block.hash.prefix(16)) + "..."
        case .mempool(let transaction):
            return String(transaction.txid.prefix(16)) + "..."
        }
    }
    
    private var transactionCount: Int? {
        switch selectedBlock {
        case .confirmed(let block):
            return block.txCount
        case .mempool(_):
            return nil
        }
    }
    
    private var blockTimestamp: String? {
        switch selectedBlock {
        case .confirmed(let block):
            let date = Date(timeIntervalSince1970: TimeInterval(block.time))
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        case .mempool(_):
            return nil
        }
    }
    
    // Mock fee distribution data for testing
    private var mockFeeData: [FeeRange] {
        [
            FeeRange(minFee: 1, maxFee: 5, txCount: 75),
            FeeRange(minFee: 6, maxFee: 10, txCount: 95),
            FeeRange(minFee: 11, maxFee: 15, txCount: 120),
            FeeRange(minFee: 16, maxFee: 20, txCount: 140),
            FeeRange(minFee: 21, maxFee: 25, txCount: 160),
            FeeRange(minFee: 26, maxFee: 30, txCount: 180),
            FeeRange(minFee: 31, maxFee: 35, txCount: 150),
            FeeRange(minFee: 36, maxFee: 40, txCount: 130),
            FeeRange(minFee: 41, maxFee: 45, txCount: 110),
            FeeRange(minFee: 46, maxFee: 50, txCount: 95),
            FeeRange(minFee: 51, maxFee: 55, txCount: 80),
            FeeRange(minFee: 56, maxFee: 60, txCount: 65),
            FeeRange(minFee: 61, maxFee: 65, txCount: 50),
            FeeRange(minFee: 66, maxFee: 70, txCount: 40),
            FeeRange(minFee: 71, maxFee: 75, txCount: 30)
        ]
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

// MARK: - Mempool Data Table

struct MempoolDataTable: View {
    let transaction: MempoolTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Median Fee
            MempoolDataRow(
                label: "Median Fee",
                value: "~\(transaction.medianFee) sat/vB"
            )
            
            // Fee Span
            MempoolDataRow(
                label: "Fee Span",
                value: feeSpanText
            )
            
            // Total Fees
            MempoolDataRow(
                label: "Total Fees",
                value: totalFeesText
            )
            
            // Number of Transactions
            MempoolDataRow(
                label: "Transactions",
                value: "\(transaction.nTx)"
            )
            
            // Block Size
            MempoolDataRow(
                label: "Block Size",
                value: blockSizeText
            )
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
        let btc = Double(transaction.totalFees) / 100_000_000.0 // Convert satoshis to BTC
        return String(format: "%.3f BTC", btc)
    }
    
    private var blockSizeText: String {
        let mb = Double(transaction.blockSize) / 1_000_000.0 // Convert bytes to MB
        return String(format: "%.2f MB", mb)
    }
}

struct MempoolDataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    Group {
        BlockDetailView(selectedBlock: .confirmed(
            Block(hash: "0000000000000000000123456789abcdef", height: 800000, time: 1693478400, txCount: 2341)
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
