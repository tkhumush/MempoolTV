//
//  MiningPoolsChartView.swift
//  memTV
//
//  Horizontal bar chart of mining pool block counts.
//

import SwiftUI
import Charts

struct MiningPoolsChartView: View {
    let data: MiningPoolsResponse?

    private let brandColors: [Color] = [
        .orange, .blue, .green, .red, .purple, .yellow, .pink, .cyan, .mint, .indigo
    ]

    var body: some View {
        VStack(spacing: 12) {
            if let data = data {
                VStack(spacing: 12) {
                    Text("Mining Pools (1 Week)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Chart(data.pools.prefix(10)) { pool in
                        BarMark(
                            x: .value("Blocks", pool.blockCount),
                            y: .value("Pool", pool.name)
                        )
                        .foregroundStyle(by: .value("Pool", pool.name))
                        .cornerRadius(4)
                        .accessibilityLabel("\(pool.name), \(pool.blockCount) blocks")
                    }
                    .chartForegroundStyleScale(domain: data.pools.prefix(10).map { $0.name }, range: brandColors)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel()
                                .foregroundStyle(.white)
                                .font(.caption2)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .foregroundStyle(.white)
                                .font(.caption2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Mining pool block counts over the last week")

                    Text("\(data.blockCount) blocks mined")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
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
}

#Preview {
    MiningPoolsChartView(data: MiningPoolsResponse(
        pools: [
            MiningPool(poolId: 1, name: "FoundryUSA", link: "", blockCount: 120, rank: 1, emptyBlocks: 0, slug: "", avgMatchRate: nil, avgFeeDelta: nil, poolUniqueId: 1),
            MiningPool(poolId: 2, name: "AntPool", link: "", blockCount: 80, rank: 2, emptyBlocks: 0, slug: "", avgMatchRate: nil, avgFeeDelta: nil, poolUniqueId: 2),
            MiningPool(poolId: 3, name: "F2Pool", link: "", blockCount: 60, rank: 3, emptyBlocks: 0, slug: "", avgMatchRate: nil, avgFeeDelta: nil, poolUniqueId: 3)
        ],
        blockCount: 1000,
        lastEstimatedHashrate: 500_000_000_000_000_000_000,
        lastEstimatedHashrate3d: nil,
        lastEstimatedHashrate1w: nil
    ))
    .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}
