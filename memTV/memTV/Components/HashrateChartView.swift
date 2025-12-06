//
//  HashrateChartView.swift
//  memTV
//
//  Created by Taymur Khumush on 12/5/25.
//

import SwiftUI
import Charts

struct HashrateChartView: View {
    @StateObject private var service = HashrateService()

    var body: some View {
        VStack(spacing: 12) {
            if service.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let data = service.hashrateData {
                VStack(spacing: 12) {
                    // Title
                    Text("Network Hashrate (90 Days)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Chart - plot last 90 data points
                    Chart(data.hashrates.suffix(90)) { point in
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

                    // Current hashrate display - use last data point
                    if let lastPoint = data.hashrates.last {
                        Text(service.formatHashrate(lastPoint.avgHashrate))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text("Current Network Hashrate")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
            } else if let error = service.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .onAppear {
            Task {
                await service.fetchHashrateData()
            }
        }
    }
}

#Preview {
    HashrateChartView()
        .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}
