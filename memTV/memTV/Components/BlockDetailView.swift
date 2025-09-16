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
        Group {
            if case .confirmed(let block) = selectedBlock {
                // 2-column table layout with alternating row colors
                VStack(spacing: 0) {
                    let items = blockDetailItems(for: block)
                    ForEach(0..<items.count, id: \.self) { index in
                        let item = items[index]
                        if !item.title.isEmpty {
                            HStack(spacing: 0) {
                                // Label cell
                                Text(item.title)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        index % 2 == 1
                                            ? Color.gray.opacity(0.15)
                                            : Color.gray.opacity(0.05)
                                    )

                                // Value cell
                                Text(item.value)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        index % 2 == 1
                                            ? Color.gray.opacity(0.15)
                                            : Color.gray.opacity(0.05)
                                    )
                            }
                        }
                    }
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Fallback to original simple view
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
        }
    }

    // MARK: - Block Detail Items

    private func blockDetailItems(for block: Block) -> [(title: String, value: String)] {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        // Only include fields that are available from mempool.space API
        var items: [(title: String, value: String)] = []

        items.append(("Hash", String(block.hash.prefix(16)) + "..."))
        items.append(("Timestamp", dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(block.time)))))

        if let size = block.size {
            items.append(("Size", "\(formatter.string(from: NSNumber(value: size)) ?? "\(size)") bytes"))
        }

        if let weight = block.weight {
            items.append(("Weight", "\(formatter.string(from: NSNumber(value: weight)) ?? "\(weight)") WU"))
        }

        if let medianFee = block.medianFee {
            items.append(("Median Fee", String(format: "%.2f sat/vB", medianFee)))
        }

        if let totalFees = block.totalFees {
            items.append(("Total Fees", String(format: "%.4f BTC", totalFees)))
        }

        // Only show Subsidy + Fees if we have both values
        if block.subsidy != nil || block.totalFees != nil {
            items.append(("Subsidy + Fees", calculateSubsidyPlusFees(for: block)))
        }

        if let miner = block.miner {
            items.append(("Miner", miner))
        }

        return items
    }

    private func calculateSubsidyPlusFees(for block: Block) -> String {
        let subsidy = block.subsidy ?? 0.0
        let totalFees = block.totalFees ?? 0.0
        let total = subsidy + totalFees
        return String(format: "%.4f BTC", total)
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
                Text("Top 10 Largest Transactions")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                // Top Transactions Chart (only for mempool transactions)
                if case .mempool(let transaction) = selectedBlock {
                    HStack {
                        TopTransactionsChart(transaction: transaction)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
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
    
    // Generate fee distribution data from mempool transaction using REAL API data
    private func generateFeeDistributionData(from transaction: MempoolTransaction) -> [FeeRange] {
        guard !transaction.feeRange.isEmpty else { 
            print("⚠️ No feeRange data available, using median fallback")
            let medianFee = Double(transaction.medianFee)
            return [FeeRange(
                minFee: Int(medianFee * 0.8),
                maxFee: Int(medianFee * 1.2),
                txCount: transaction.nTx
            )]
        }
        
        // Print the raw data for debugging
        print("🔍 Raw feeRange from API: \(transaction.feeRange)")
        print("📊 Raw feeRange count: \(transaction.feeRange.count)")
        
        // Sort the fee range data
        let sortedFees = transaction.feeRange.sorted()
        print("📈 Sorted feeRange: \(sortedFees)")
        
        // Create simple percentile-to-fee mapping
        var feeRanges: [FeeRange] = []
        
        // Map each fee in sortedFees to its corresponding percentile
        for (index, feeRate) in sortedFees.enumerated() {
            // Calculate percentile (0 to 100)
            let percentile = Double(index) / Double(sortedFees.count - 1) * 100.0
            
            // Print the mapping for debugging
            print("📍 Percentile \(String(format: "%.1f", percentile)): \(feeRate) sat/vB")
            
            // Store as simple fee range - use the fee rate directly
            feeRanges.append(FeeRange(
                minFee: Int(feeRate * 1000), // Preserve precision with millisats
                maxFee: Int(feeRate * 1000), // Same value for point
                txCount: 1 // Simplified - each point gets weight 1
            ))
        }
        
        print("✅ Generated \(feeRanges.count) fee ranges for chart")
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

// MARK: - Block Detail Cell

struct BlockDetailCell: View {
    let title: String
    let value: String
    let isAlternatingRow: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !title.isEmpty {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(value)
                    .font(.caption)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            isAlternatingRow
                ? Color.gray.opacity(0.15)
                : Color.gray.opacity(0.05)
        )
    }
}

// MARK: - Preview

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
