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
    
    // Transform fee range data into percentile data
    private var percentileData: [PercentilePoint] {
        generatePercentileData(from: feeData)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if percentileData.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: chartHeight)
                    .overlay(
                        Text("Fee distribution data not available")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
            } else {
                percentileChart
                
                // Updated legend for line chart
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Extract chart into computed property to help compiler
    private var percentileChart: some View {
        Chart(percentileData, id: \.percentile) { point in
            // Area fill under the line
            AreaMark(
                x: .value("Percentile", point.percentile),
                y: .value("Fee (sat/vB)", point.feeRate)
            )
            .foregroundStyle(areaGradient)
            
            // Line chart - no smoothing for accurate representation
            LineMark(
                x: .value("Percentile", point.percentile),
                y: .value("Fee (sat/vB)", point.feeRate)
            )
            .foregroundStyle(Color.blue)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.linear)
            
            // Data point markers removed for clean line appearance
        }
        .frame(height: chartHeight)
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.25))
                AxisTick()
                    .foregroundStyle(Color.gray)
                AxisValueLabel {
                    Text(formatYAxisLabel(value.as(Double.self) ?? 0))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.gray)
                }
            }
        }
        .chartYScale(domain: yAxisDomain, type: .log)
        .chartXAxis {
            AxisMarks(values: .stride(by: 10)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.15))
                AxisTick()
                    .foregroundStyle(Color.gray)
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.gray)
            }
        }
        .chartXAxisLabel("% Weight", alignment: .center)
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
    }
    
    private var areaGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.3),
                Color.blue.opacity(0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Smart logarithmic Y-axis scaling - SIMPLIFIED
    private var yAxisValues: [Double] {
        guard !percentileData.isEmpty else { return [0.1, 1, 10, 100] }
        
        let maxFee = percentileData.map { $0.feeRate }.max() ?? 1.0
        let minFee = percentileData.map { $0.feeRate }.min() ?? 0.1
        
        print("📊 Y-axis scaling - Min fee: \(minFee), Max fee: \(maxFee)")
        
        // Simple logarithmic scale - always include key points
        var values = [0.1, 1.0, 10.0, 100.0]
        
        // Add intermediate points based on data range
        if maxFee >= 500 {
            values.append(500.0)
        } else if maxFee >= 200 {
            values.append(200.0)
        } else if maxFee >= 50 {
            values.append(50.0)
        }
        
        // Add smaller intermediate points if needed
        if minFee < 0.5 && maxFee > 0.5 {
            values.append(0.5)
        }
        if maxFee > 2 && maxFee < 50 {
            values.append(2.0)
            values.append(5.0)
        }
        
        let sortedValues = values.sorted()
        print("📈 Y-axis values: \(sortedValues)")
        return sortedValues
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !percentileData.isEmpty else { return 0.1...100 }
        
        let maxFee = percentileData.map { $0.feeRate }.max() ?? 1.0
        
        // Set reasonable bounds
        let lowerBound = 0.1
        let upperBound = getReasonableUpperBound(for: maxFee)
        
        return lowerBound...upperBound
    }
    
    private func getReasonableUpperBound(for maxFee: Double) -> Double {
        // Smart upper bound - don't jump unnecessarily high
        if maxFee <= 2 { return 5 }
        if maxFee <= 5 { return 10 }
        if maxFee <= 10 { return 20 }
        if maxFee <= 20 { return 50 }
        if maxFee <= 50 { return 100 }
        if maxFee <= 100 { return 200 }
        if maxFee <= 200 { return 500 }
        return 1000 // Only for extremely high fees
    }
    
    private func formatYAxisLabel(_ value: Double) -> String {
        if value < 1 {
            return String(format: "%.1f", value)
        } else if value < 10 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    // Helper functions
    private func shouldShowLabel(for percentile: Double) -> Bool {
        // Show labels for median (50th), 90th percentile, and 100th percentile
        return percentile == 50.0 || percentile == 90.0 || percentile == 100.0
    }
    
    private func formatFeeRate(_ feeRate: Double) -> String {
        if feeRate >= 100 {
            return String(format: "%.0f", feeRate)
        } else if feeRate >= 10 {
            return String(format: "%.1f", feeRate)
        } else {
            return String(format: "%.2f", feeRate)
        }
    }
    
    // Generate percentile data from fee range data - SIMPLIFIED APPROACH
    private func generatePercentileData(from feeRanges: [FeeRange]) -> [PercentilePoint] {
        guard !feeRanges.isEmpty else { 
            print("⚠️ No feeRanges provided to chart")
            return [] 
        }
        
        print("📊 Chart received \(feeRanges.count) fee ranges")
        
        // Sort by fee rate (stored as millisats)
        let sortedRanges = feeRanges.sorted { $0.minFee < $1.minFee }
        
        var percentilePoints: [PercentilePoint] = []
        
        // Generate data points for every single percentile (1, 2, 3, 4, ..., 100)
        for percentile in stride(from: 1, through: 100, by: 1) {
            // Find the closest fee range for this percentile
            let targetIndex = Int(Double(percentile) / 100.0 * Double(sortedRanges.count - 1))
            let clampedIndex = min(max(targetIndex, 0), sortedRanges.count - 1)
            let range = sortedRanges[clampedIndex]
            
            // Convert millisats back to sat/vB
            let feeRate = Double(range.minFee) / 1000.0
            
            // Print mapping for debugging (every 10th percentile to avoid spam)
            if percentile % 10 == 0 {
                print("📈 Chart mapping - Percentile \(percentile): \(feeRate) sat/vB")
            }
            
            percentilePoints.append(PercentilePoint(
                percentile: Double(percentile),
                feeRate: feeRate
            ))
        }
        
        print("✅ Chart generated \(percentilePoints.count) percentile points")
        return percentilePoints
    }
}

// MARK: - Data Models

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

struct PercentilePoint {
    let percentile: Double  // 10th, 20th, 30th, ... 100th percentile
    let feeRate: Double     // Fee rate in sat/vB at this percentile
}

// MARK: - Preview

#Preview {
    Group {
        // With realistic fee distribution data showing typical Bitcoin mempool curve
        FeeDistributionChart(feeData: [
            FeeRange(minFee: 1, maxFee: 3, txCount: 450),      // Low fee transactions (bulk)
            FeeRange(minFee: 4, maxFee: 8, txCount: 680),      // Most common range
            FeeRange(minFee: 9, maxFee: 15, txCount: 520),     // Medium fees
            FeeRange(minFee: 16, maxFee: 25, txCount: 320),    // Higher fees
            FeeRange(minFee: 26, maxFee: 40, txCount: 180),    // Premium fees
            FeeRange(minFee: 41, maxFee: 65, txCount: 95),     // High priority
            FeeRange(minFee: 66, maxFee: 100, txCount: 45),    // Very high priority
            FeeRange(minFee: 101, maxFee: 200, txCount: 25)    // Emergency/RBF transactions
        ])
        .frame(maxWidth: 600)
        
        // Empty state
        FeeDistributionChart(feeData: [])
            .frame(maxWidth: 600)
    }
    .background(Color.black)
    .padding()
}
