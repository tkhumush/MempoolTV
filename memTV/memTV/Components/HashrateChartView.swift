//
//  HashrateChartView.swift
//  memTV
//
//  90-day network hashrate area chart driven by shared data.
//

import SwiftUI
import Charts

struct HashrateChartView: View {
    let data: HashrateResponse?

    var body: some View {
        VStack(spacing: 12) {
            if let data = data {
                VStack(spacing: 12) {
                    Text("Network Hashrate (90 Days)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Chart(data.hashrates) { point in
                        LineMark(
                            x: .value("Date", Date(timeIntervalSince1970: TimeInterval(point.timestamp))),
                            y: .value("Hashrate", point.avgHashrate / 1_000_000_000_000_000_000)
                        )
                        .foregroundStyle(Color.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", Date(timeIntervalSince1970: TimeInterval(point.timestamp))),
                            y: .value("Hashrate", point.avgHashrate / 1_000_000_000_000_000_000)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange.opacity(0.5), Color.orange.opacity(0.1)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom, values: .stride(by: .day, count: 15)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel(format: .dateTime.month().day())
                                .foregroundStyle(.white)
                                .font(.caption2)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel()
                                .foregroundStyle(.white)
                                .font(.caption2)
                        }
                    }
                    .accessibilityLabel("Network hashrate over the last 90 days")

                    if let lastPoint = data.hashrates.last {
                        Text(formatHashrate(lastPoint.avgHashrate))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text("Current Network Hashrate")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }

    private func formatHashrate(_ hashrate: Double) -> String {
        let exahash = hashrate / 1_000_000_000_000_000_000
        return String(format: "%.2f EH/s", exahash)
    }
}

#Preview {
    HashrateChartView(data: HashrateResponse(
        hashrates: [
            HashrateDataPoint(timestamp: 1_700_000_000, avgHashrate: 450_000_000_000_000_000_000),
            HashrateDataPoint(timestamp: 1_700_086_400, avgHashrate: 500_000_000_000_000_000_000)
        ],
        currentHashrate: 500_000_000_000_000_000_000,
        currentDifficulty: 83_000_000_000_000
    ))
    .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}
