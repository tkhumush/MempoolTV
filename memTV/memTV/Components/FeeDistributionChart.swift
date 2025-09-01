//
//  FeeDistributionChart.swift
//  memTV
//
//  Created by Taymur Khumush on 9/1/25.
//

import SwiftUI

struct FeeDistributionChart: View {
    let feeData: [FeeRange]
    let maxHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                // Chart with axes
                HStack(alignment: .bottom, spacing: 0) {
                    // Y-axis
                    YAxisView(maxTxCount: feeData.map({ $0.txCount }).max() ?? 0, height: maxHeight)
                    
                    // Chart area
                    GeometryReader { geometry in
                        HStack(alignment: .bottom, spacing: calculateSpacing(for: geometry.size.width)) {
                            ForEach(Array(feeData.enumerated()), id: \.offset) { index, range in
                                FeeBar(
                                    feeRange: range,
                                    height: calculateBarHeight(for: range),
                                    color: colorForFeeRange(range),
                                    width: calculateBarWidth(for: geometry.size.width)
                                )
                            }
                        }
                    }
                    .frame(height: maxHeight)
                }
                
                // Legend with proper spacing
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 12)
                    FeeDistributionLegend()
                }.padding()
            }
        }
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
    
    private func calculateBarWidth(for containerWidth: CGFloat) -> CGFloat {
        let barCount = CGFloat(feeData.count)
        let totalSpacing = calculateSpacing(for: containerWidth) * (barCount - 1)
        let availableWidth = containerWidth - totalSpacing
        return max(availableWidth / barCount, 1) // Minimum 1pt width
    }
    
    private func calculateSpacing(for containerWidth: CGFloat) -> CGFloat {
        // Use 2% of container width for spacing, minimum 2pts
        return max(containerWidth * 0.02, 2)
    }
}

// MARK: - Supporting Views

struct FeeBar: View {
    let feeRange: FeeRange
    let height: CGFloat
    let color: Color
    let width: CGFloat
    
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 15)
                .fill(color)
                .frame(width: width-3, height: height)
        }
    }
}

struct FeeDistributionLegend: View {
    var body: some View {
        HStack(spacing: 20) {
            LegendItem(color: .green, label: "Low (1-9)")
            LegendItem(color: .mint, label: "Low-Med (10-19)")
            LegendItem(color: .yellow, label: "Medium (20-29)")
            LegendItem(color: .orange, label: "Med-High (30-44)")
            LegendItem(color: .pink, label: "High (45-59)")
            LegendItem(color: .red, label: "Very High (60+)")
        }
        .font(.system(size: 17))
        .padding(.leading , 30)
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

struct YAxisView: View {
    let maxTxCount: Int
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Y-axis labels from top to bottom
            ForEach(yAxisLabels.reversed(), id: \.self) { value in
                VStack {
                    if value == yAxisLabels.last {
                        Spacer().frame(height: 100)
                    } else {
                        Spacer()
                    }
                    
                    Text("\(value)")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .frame(height: 12)
                    
                    if value == yAxisLabels.first {
                        Spacer().frame(height: 400)
                    } else {
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 50, height: 1)
    }
    
    private var yAxisLabels: [Int] {
        let stepCount = 5
        let step = max(1, maxTxCount / stepCount)
        let roundedStep = roundToNearestPowerOf10(step)
        
        var labels: [Int] = []
        for i in 0...stepCount {
            let value = i * roundedStep
            if value <= maxTxCount * 110 / 100 { // Allow 10% overhead for better scaling
                labels.append(value)
            }
        }
        
        if labels.last != maxTxCount && !labels.contains(where: { $0 >= maxTxCount }) {
            labels.append(maxTxCount)
        }
        
        return labels
    }
    
    private func roundToNearestPowerOf10(_ number: Int) -> Int {
        if number <= 0 { return 1 }
        let digits = String(number).count
        let powerOf10 = Int(pow(10.0, Double(digits - 1)))
        return ((number / powerOf10) + (number % powerOf10 > 0 ? 1 : 0)) * powerOf10
    }
}

struct XAxisView: View {
    let feeData: [FeeRange]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: calculateSpacing(for: geometry.size.width)) {
                ForEach(Array(feeData.enumerated()), id: \.offset) { index, range in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: calculateBarWidth(for: geometry.size.width), height: 1)
                        
                        Text(formatFeeRange(range))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(width: calculateBarWidth(for: geometry.size.width))
                            .rotationEffect(.degrees(-45))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(height: 30)
                }
            }
        }
        .frame(height: 30)
    }
    
    private func calculateBarWidth(for containerWidth: CGFloat) -> CGFloat {
        let barCount = CGFloat(feeData.count)
        let totalSpacing = calculateSpacing(for: containerWidth) * (barCount - 1)
        let availableWidth = containerWidth - totalSpacing
        return max(availableWidth / barCount, 1)
    }
    
    private func calculateSpacing(for containerWidth: CGFloat) -> CGFloat {
        return max(containerWidth * 0.02, 2)
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
