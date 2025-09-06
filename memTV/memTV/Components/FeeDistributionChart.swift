//
//  FeeDistributionChart.swift
//  memTV
//
//  Created by Taymur Khumush on 9/1/25.
//

import SwiftUI
import Charts

struct FeeDistributionChart: View {
    let feeData: [FeeRange]
    let chartHeight: CGFloat = 180
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if feeData.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: chartHeight)
                    .overlay(
                        Text("Fee distribution data not available")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
            } else {
                Chart(feeData, id: \.minFee) { range in
                    BarMark(
                        x: .value("Fee Range", formatFeeRange(range)),
                        y: .value("Transaction Count", range.txCount)
                    )
                    .foregroundStyle(colorForFeeRange(range))
                    .cornerRadius(3)
                    .accessibilityLabel("\(formatFeeRange(range)) sats/vB")
                    .accessibilityValue("\(range.txCount) transactions")
                }
                .frame(height: chartHeight)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.25))
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Legend
                FeeDistributionLegend()
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func colorForFeeRange(_ range: FeeRange) -> Color {
        if range.minFee >= 60 {
            return .red         // Very high priority (60+ sat/vB)
        } else if range.minFee >= 45 {
            return .pink        // High priority (45-59 sat/vB)
        } else if range.minFee >= 30 {
            return .orange      // Medium-high priority (30-44 sat/vB)
        } else if range.minFee >= 20 {
            return .yellow      // Medium priority (20-29 sat/vB)
        } else if range.minFee >= 10 {
            return .mint        // Low-medium priority (10-19 sat/vB)
        } else {
            return .green       // Low priority (1-9 sat/vB)
        }
    }
    
    private func formatFeeRange(_ range: FeeRange) -> String {
        if range.minFee == range.maxFee {
            return "\(range.minFee)"
        } else if range.maxFee >= 100 {
            return "\(range.minFee)+"
        } else {
            return "\(range.minFee)-\(range.maxFee)"
        }
    }
}

// MARK: - Supporting Views

struct FeeDistributionLegend: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                LegendItem(color: .green, label: "Low (1-9)")
                LegendItem(color: .mint, label: "Low-Med (10-19)")
                LegendItem(color: .yellow, label: "Medium (20-29)")
                LegendItem(color: .orange, label: "Med-High (30-44)")
                LegendItem(color: .pink, label: "High (45-59)")
                LegendItem(color: .red, label: "Very High (60+)")
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .font(.system(size: 15))
        }
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
