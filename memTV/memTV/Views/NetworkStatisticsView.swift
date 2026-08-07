//
//  NetworkStatisticsView.swift
//  memTV
//
//  Network statistics dashboard with a unified ViewModel.
//

import SwiftUI

struct NetworkStatisticsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var viewModel: NetworkStatsViewModel

    var body: some View {
        ZStack {
            themeManager.contentViewBackgroundColor
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header with logo - matching main screen
                HStack {
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
                    DifficultyAdjustmentWidget(data: viewModel.difficultyData)

                    HStack(spacing: 20) {
                        MiningPoolsChartView(data: viewModel.poolsData)

                        HashrateChartView(data: viewModel.hashrateData)
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
    let viewModel = NetworkStatsViewModel()
    viewModel.hashrateState = .loaded(HashrateResponse(
        hashrates: [],
        currentHashrate: 500_000_000_000_000_000_000,
        currentDifficulty: 83_000_000_000_000
    ))
    viewModel.poolsState = .loaded(MiningPoolsResponse(
        pools: [
            MiningPool(poolId: 1, name: "FoundryUSA", link: "", blockCount: 120, rank: 1, emptyBlocks: 0, slug: "", avgMatchRate: nil, avgFeeDelta: nil, poolUniqueId: 1),
            MiningPool(poolId: 2, name: "AntPool", link: "", blockCount: 80, rank: 2, emptyBlocks: 0, slug: "", avgMatchRate: nil, avgFeeDelta: nil, poolUniqueId: 2)
        ],
        blockCount: 1000,
        lastEstimatedHashrate: 500_000_000_000_000_000_000,
        lastEstimatedHashrate3d: nil,
        lastEstimatedHashrate1w: nil
    ))

    return NetworkStatisticsView()
        .environmentObject(ThemeManager())
        .environmentObject(viewModel)
}
