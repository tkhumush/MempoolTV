//
//  DifficultyAdjustmentWidget.swift
//  memTV
//
//  Created by Taymur Khumush on 12/5/25.
//

import SwiftUI

struct DifficultyAdjustmentWidget: View {
    @StateObject private var service = DifficultyAdjustmentService()

    var body: some View {
        VStack(spacing: 16) {
            if service.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else if let data = service.difficultyData {
                VStack(spacing: 12) {
                    // Title
                    Text("Difficulty Adjustment")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Progress bar
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 30)
                                    .cornerRadius(15)

                                // Progress fill
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * (data.progressPercent / 100), height: 30)
                                    .cornerRadius(15)

                                // Percentage text
                                Text("\(String(format: "%.1f", data.progressPercent))%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 30)
                    }

                    // Stats grid
                    HStack(spacing: 40) {
                        statItem(
                            title: "Estimated Change",
                            value: "\(data.difficultyChange > 0 ? "+" : "")\(String(format: "%.2f", data.difficultyChange))%",
                            color: data.difficultyChange > 0 ? .green : .red
                        )

                        statItem(
                            title: "Blocks Remaining",
                            value: "\(data.remainingBlocks)",
                            color: .white
                        )

                        statItem(
                            title: "Time Remaining",
                            value: service.formatTimeRemaining(data.remainingTime),
                            color: .white
                        )

                        statItem(
                            title: "Avg Block Time",
                            value: service.formatAvgBlockTime(data.timeAvg),
                            color: .white
                        )
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
                await service.fetchDifficultyAdjustment()
            }
        }
    }

    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    DifficultyAdjustmentWidget()
        .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}
