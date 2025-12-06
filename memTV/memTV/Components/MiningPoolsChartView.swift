//
//  MiningPoolsChartView.swift
//  memTV
//
//  Created by Taymur Khumush on 12/5/25.
//

import SwiftUI
import Charts

struct MiningPoolsChartView: View {
    @StateObject private var service = MiningPoolsService()

    var body: some View {
        VStack(spacing: 12) {
            if service.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let data = service.poolsData {
                VStack(spacing: 12) {
                    // Title
                    Text("Mining Pools (1 Week)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Chart with Legend on the left
                    HStack(spacing: 20) {
                        // Legend on the left
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(data.pools.prefix(10)) { pool in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(
                                            hue: Double(pool.rank) / 10.0,
                                            saturation: 0.7,
                                            brightness: 0.9
                                        ))
                                        .frame(width: 10, height: 10)
                                    Text(pool.name)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .frame(maxWidth: 150)

                        // Chart on the right
                        Chart(data.pools.prefix(10)) { pool in
                            SectorMark(
                                angle: .value("Blocks", pool.blockCount),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(
                                Color(
                                    hue: Double(pool.rank) / 10.0,
                                    saturation: 0.7,
                                    brightness: 0.9
                                )
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Total blocks
                    Text("\(data.blockCount) blocks mined")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
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
                await service.fetchMiningPools()
            }
        }
    }
}

#Preview {
    MiningPoolsChartView()
        .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}
