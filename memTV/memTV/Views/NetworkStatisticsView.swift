//
//  NetworkStatisticsView.swift
//  memTV
//
//  Created by Taymur Khumush on 12/5/25.
//

import SwiftUI

struct NetworkStatisticsView: View {
    @StateObject private var themeManager = ThemeManager()

    var body: some View {
        ZStack {
            // Theme-aware background
            themeManager.contentViewBackgroundColor
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header with logo - matching main screen
                HStack {
                    // App icon logo
                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                        .cornerRadius(12)

                    Spacer()

                    Text("Network Statistics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 1)
                .padding(.top, 5)
                .padding(.bottom, 1)

                // Layout: VStack with difficulty widget, then HStack with two charts
                VStack(spacing: 20) {
                    // Top row - Difficulty Adjustment (spans full width)
                    DifficultyAdjustmentWidget()

                    // Bottom row - Two charts side by side
                    HStack(spacing: 20) {
                        MiningPoolsChartView()

                        HashrateChartView()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)

                Spacer()
            }
        }
    }
}

#Preview {
    NetworkStatisticsView()
}
