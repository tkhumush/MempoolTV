//
//  FeeDistributionChart.swift
//  memTV
//
//  Fee distribution area/line chart.
//

import SwiftUI
import Charts

struct FeeDistributionChart: View {
    let feeData: [FeeRange]
    let chartHeight: CGFloat = 180

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
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fee distribution by weight percentile")
    }

    private var percentileChart: some View {
        Chart(percentileData, id: \.percentile) { point in
            AreaMark(
                x: .value("Percentile", point.percentile),
                y: .value("Fee (sat/vB)", point.feeRate)
            )
            .foregroundStyle(areaGradient)

            LineMark(
                x: .value("Percentile", point.percentile),
                y: .value("Fee (sat/vB)", point.feeRate)
            )
            .foregroundStyle(Color.blue)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.linear)
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

    private var yAxisValues: [Double] {
        guard !percentileData.isEmpty else { return [0.1, 1, 10, 100] }

        let maxFee = percentileData.map { $0.feeRate }.max() ?? 1.0
        let minFee = percentileData.map { $0.feeRate }.min() ?? 0.1

        var values = [0.1, 1.0, 10.0, 100.0]

        if maxFee >= 500 {
            values.append(500.0)
        } else if maxFee >= 200 {
            values.append(200.0)
        } else if maxFee >= 50 {
            values.append(50.0)
        }

        if minFee < 0.5 && maxFee > 0.5 {
            values.append(0.5)
        }
        if maxFee > 2 && maxFee < 50 {
            values.append(2.0)
            values.append(5.0)
        }

        return values.sorted()
    }

    private var yAxisDomain: ClosedRange<Double> {
        guard !percentileData.isEmpty else { return 0.1...100 }

        let maxFee = percentileData.map { $0.feeRate }.max() ?? 1.0
        let lowerBound = 0.1
        let upperBound = getReasonableUpperBound(for: maxFee)

        return lowerBound...upperBound
    }

    private func getReasonableUpperBound(for maxFee: Double) -> Double {
        if maxFee <= 2 { return 5 }
        if maxFee <= 5 { return 10 }
        if maxFee <= 10 { return 20 }
        if maxFee <= 20 { return 50 }
        if maxFee <= 50 { return 100 }
        if maxFee <= 100 { return 200 }
        if maxFee <= 200 { return 500 }
        return 1000
    }

    private func formatYAxisLabel(_ value: Double) -> String {
        if value < 1 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
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

    private func generatePercentileData(from feeRanges: [FeeRange]) -> [PercentilePoint] {
        guard !feeRanges.isEmpty else { return [] }

        let sortedRanges = feeRanges.sorted { $0.minFee < $1.minFee }

        var percentilePoints: [PercentilePoint] = []

        for percentile in stride(from: 1, through: 100, by: 1) {
            let targetIndex = Int(Double(percentile) / 100.0 * Double(sortedRanges.count - 1))
            let clampedIndex = min(max(targetIndex, 0), sortedRanges.count - 1)
            let range = sortedRanges[clampedIndex]
            let feeRate = Double(range.minFee) / 1000.0

            percentilePoints.append(PercentilePoint(
                percentile: Double(percentile),
                feeRate: feeRate
            ))
        }

        return percentilePoints
    }
}

struct PercentilePoint {
    let percentile: Double
    let feeRate: Double
}

#Preview {
    Group {
        FeeDistributionChart(feeData: [
            FeeRange(minFee: 1, maxFee: 3, txCount: 450),
            FeeRange(minFee: 4, maxFee: 8, txCount: 680),
            FeeRange(minFee: 9, maxFee: 15, txCount: 520),
            FeeRange(minFee: 16, maxFee: 25, txCount: 320),
            FeeRange(minFee: 26, maxFee: 40, txCount: 180),
            FeeRange(minFee: 41, maxFee: 65, txCount: 95),
            FeeRange(minFee: 66, maxFee: 100, txCount: 45),
            FeeRange(minFee: 101, maxFee: 200, txCount: 25)
        ])
        .frame(maxWidth: 600)

        FeeDistributionChart(feeData: [])
            .frame(maxWidth: 600)
    }
    .background(Color.black)
    .padding()
}
