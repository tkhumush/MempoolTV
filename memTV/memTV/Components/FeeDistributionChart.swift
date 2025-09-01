//
//  FeeDistributionChart.swift
//  memTV
//
//  Created by Taymur Khumush on 9/1/25.
//

import SwiftUI

struct FeeDistributionChart: View {
    let feeData: [FeeRange]
    let maxHeight: CGFloat = 150
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fee Distribution")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if feeData.isEmpty {
                // Placeholder state
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: maxHeight)
                    .overlay(
                        Text("Fee distribution data not available")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
            } else {
                // Chart area
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(feeData.enumerated()), id: \.offset) { index, range in
                        FeeBar(
                            feeRange: range,
                            height: calculateBarHeight(for: range),
                            color: colorForFeeRange(range)
                        )
                    }
                }
                .frame(height: maxHeight)
                
                // Legend
                FeeDistributionLegend()
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func calculateBarHeight(for range: FeeRange) -> CGFloat {
        guard let maxTxCount = feeData.map({ $0.txCount }).max(), maxTxCount > 0 else {
            return 0
        }
        return (CGFloat(range.txCount) / CGFloat(maxTxCount)) * maxHeight
    }
    
    private func colorForFeeRange(_ range: FeeRange) -> Color {
        if range.minFee >= 50 {
            return .red      // High priority
        } else if range.minFee >= 20 {
            return .orange   // Medium priority
        } else if range.minFee >= 10 {
            return .yellow   // Low priority
        } else {
            return .green    // Very low priority
        }
    }
}

// MARK: - Supporting Views

struct FeeBar: View {
    let feeRange: FeeRange
    let height: CGFloat
    let color: Color
    
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: height)
        }
    }
}

struct FeeDistributionLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            LegendItem(color: .red, label: "High (50+ sat/vB)")
            LegendItem(color: .orange, label: "Medium (20-49)")
            LegendItem(color: .yellow, label: "Low (10-19)")
            LegendItem(color: .green, label: "Very Low (<10)")
        }
        .font(.caption2)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Data Model

struct FeeRange {
    let minFee: Int      // Minimum fee in sat/vB
    let maxFee: Int      // Maximum fee in sat/vB  
    let txCount: Int     // Number of transactions in this range
    
    init(minFee: Int, maxFee: Int, txCount: Int) {
        self.minFee = minFee
        self.maxFee = maxFee
        self.txCount = txCount
    }
}

// MARK: - Preview

#Preview {
    Group {
        // With data
        FeeDistributionChart(feeData: [
            FeeRange(minFee: 1, maxFee: 5, txCount: 150),
            FeeRange(minFee: 6, maxFee: 10, txCount: 200),
            FeeRange(minFee: 11, maxFee: 20, txCount: 300),
            FeeRange(minFee: 21, maxFee: 50, txCount: 180),
            FeeRange(minFee: 51, maxFee: 100, txCount: 120),
            FeeRange(minFee: 101, maxFee: 200, txCount: 80)
        ])
        
        // Empty state
        FeeDistributionChart(feeData: [])
    }
    .background(Color.black)
    .padding()
}