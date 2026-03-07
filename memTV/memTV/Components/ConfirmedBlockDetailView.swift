//
//  ConfirmedBlockDetailView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/31/25.
//

import SwiftUI

struct ConfirmedBlockDetailView: View {
    let block: Block

    var body: some View {
        VStack(spacing: 0) {
            let items = blockDetailItems(for: block)
            ForEach(0..<items.count, id: \.self) { index in
                let item = items[index]
                if !item.title.isEmpty {
                    HStack(spacing: 0) {
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
    }

    private func blockDetailItems(for block: Block) -> [(title: String, value: String)] {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

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

        if block.subsidy != nil || block.totalFees != nil {
            let subsidy = block.subsidy ?? 0.0
            let fees = block.totalFees ?? 0.0
            items.append(("Subsidy + Fees", String(format: "%.4f BTC", subsidy + fees)))
        }

        if let miner = block.miner {
            items.append(("Miner", miner))
        }

        return items
    }
}
