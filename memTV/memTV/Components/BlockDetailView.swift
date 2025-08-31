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
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(blockTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                StatusBadge(isConfirmed: isConfirmed)
            }
            .padding(.bottom, 10)
            
            // Details Grid
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
            
            Spacer()
        }
        .padding(40)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
    
    // MARK: - Computed Properties
    
    private var isConfirmed: Bool {
        switch selectedBlock {
        case .confirmed(_):
            return true
        case .mempool(_, _):
            return false
        }
    }
    
    private var blockTitle: String {
        switch selectedBlock {
        case .confirmed(_):
            return "Confirmed Block"
        case .mempool(_, _):
            return "Mempool Transaction"
        }
    }
    
    private var blockNumber: String {
        switch selectedBlock {
        case .confirmed(let block):
            return "\(block.height)"
        case .mempool(_, let displayNumber):
            return "\(displayNumber)"
        }
    }
    
    private var hashValue: String {
        switch selectedBlock {
        case .confirmed(let block):
            return String(block.hash.prefix(16)) + "..."
        case .mempool(let txId, _):
            return String(txId.prefix(16)) + "..."
        }
    }
    
    private var transactionCount: Int? {
        switch selectedBlock {
        case .confirmed(let block):
            return block.txCount
        case .mempool(_, _):
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
        case .mempool(_, _):
            return nil
        }
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

// MARK: - Preview

#Preview {
    Group {
        BlockDetailView(selectedBlock: .confirmed(
            Block(hash: "0000000000000000000123456789abcdef", height: 800000, time: 1693478400, txCount: 2341)
        ))
        
        BlockDetailView(selectedBlock: .mempool("abc123def456ghi789jkl", 12345))
    }
    .background(Color.black)
}