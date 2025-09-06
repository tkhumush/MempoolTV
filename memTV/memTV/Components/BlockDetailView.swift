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
            // Header
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
            case .confirmed(_):
                // Existing confirmed block layout
                confirmedBlockView
            case .mempool(let transaction):
                // New mempool block layout
                mempoolBlockView(transaction: transaction)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }
    
    // MARK: - Confirmed Block View
    
    private var confirmedBlockView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), alignment: .leading, spacing: 5) {
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
        HStack(alignment: .top, spacing: 50) {
            // Left side: Data table
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
                
                // Fee Distribution Chart (only for mempool transactions)
                if case .mempool(let transaction) = selectedBlock {
                    HStack {
                        FeeDistributionChart(feeData: generateFeeDistributionData(from: transaction))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side: Transaction visualization
            VStack(alignment: .leading, spacing: 5) {
                Text("Transactions by Size")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 545)
                    .overlay(
                        Text("Transaction Size\nVisualization\n(Coming Soon)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    )
                    .cornerRadius(15)
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
    
    // Generate fee distribution data from mempool transaction
    private func generateFeeDistributionData(from transaction: MempoolTransaction) -> [FeeRange] {
        guard !transaction.feeRange.isEmpty else { return [] }
        
        // Sort fee range data
        let sortedFees = transaction.feeRange.sorted()
        
        // Create fee ranges based on the actual fee data
        // We'll create reasonable ranges that represent the distribution
        let totalTxCount = transaction.nTx
        var feeRanges: [FeeRange] = []
        
        if sortedFees.count >= 2 {
            let minFee = sortedFees.first ?? 0
            let maxFee = sortedFees.last ?? 1
            
            // Create 8-12 ranges based on the spread
            let rangeCount = min(max(sortedFees.count, 8), 12)
            let feeStep = (maxFee - minFee) / Double(rangeCount - 1)
            
            for i in 0..<rangeCount {
                let rangeMinFee = minFee + (feeStep * Double(i))
                let rangeMaxFee = i == rangeCount - 1 ? maxFee : rangeMinFee + feeStep
                
                // Estimate transaction count for this range
                // Use a normal distribution curve - more transactions in middle ranges
                let normalizedPosition = Double(i) / Double(rangeCount - 1)
                let bellCurve = exp(-pow((normalizedPosition - 0.5) * 4, 2))
                let estimatedTxCount = Int(Double(totalTxCount) * bellCurve * 0.3) + (totalTxCount / (rangeCount * 2))
                
                feeRanges.append(FeeRange(
                    minFee: Int(rangeMinFee.rounded()),
                    maxFee: Int(rangeMaxFee.rounded()),
                    txCount: max(estimatedTxCount, 1)
                ))
            }
        } else {
            // Fallback: create a single range if we have limited data
            let medianFee = Double(transaction.medianFee)
            feeRanges.append(FeeRange(
                minFee: Int(medianFee * 0.8),
                maxFee: Int(medianFee * 1.2),
                txCount: totalTxCount
            ))
        }
        
        return feeRanges
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
                .font(.system(size: 20, weight: .medium))
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
