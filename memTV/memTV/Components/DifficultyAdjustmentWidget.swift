//
//  DifficultyAdjustmentWidget.swift
//  memTV
//
//  Difficulty adjustment progress widget driven by shared data.
//

import SwiftUI

struct DifficultyAdjustmentWidget: View {
    let data: DifficultyAdjustment?

    var body: some View {
        VStack(spacing: 16) {
            if let data = data {
                VStack(spacing: 12) {
                    Text("Difficulty Adjustment")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 30)
                                    .cornerRadius(15)

                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * (data.progressPercent / 100), height: 30)
                                    .cornerRadius(15)

                                Text("\(String(format: "%.1f", data.progressPercent))%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 30)
                    }

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
                            value: formatTimeRemaining(data.remainingTime),
                            color: .white
                        )

                        statItem(
                            title: "Avg Block Time",
                            value: formatAvgBlockTime(data.timeAvg),
                            color: .white
                        )
                    }
                }
                .padding()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
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

    private func formatTimeRemaining(_ seconds: Int) -> String {
        let correctedSeconds = Double(seconds) / 1000.0
        let days = correctedSeconds / 86400.0
        return String(format: "%.1fd", days)
    }

    private func formatAvgBlockTime(_ seconds: Double) -> String {
        let correctedSeconds = seconds / 1000.0
        let minutes = correctedSeconds / 60.0
        return String(format: "%.1fm", minutes)
    }
}

#Preview {
    DifficultyAdjustmentWidget(data: DifficultyAdjustment(
        progressPercent: 45.5,
        difficultyChange: 2.3,
        estimatedRetargetDate: 1_700_000_000,
        remainingBlocks: 1100,
        remainingTime: 6_000_000,
        previousRetarget: -1.2,
        previousTime: 1_690_000_000,
        nextRetargetHeight: 804_000,
        timeAvg: 600_000,
        adjustedTimeAvg: nil,
        timeOffset: 0,
        expectedBlocks: 1234
    ))
    .background(Color(red: 51/255, green: 153/255, blue: 204/255))
}
