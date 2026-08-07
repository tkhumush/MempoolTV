//
//  ContentView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//  Copyright © 2025 Taymur Khumush. All rights reserved.
//
//  This file is part of MempoolTV, licensed under the MIT License.
//  See LICENSE file in the project root for full license information.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: MempoolViewModel
    @StateObject private var networkStatsViewModel: NetworkStatsViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingDevelopersView = false
    @State private var navigationPath = NavigationPath()

    @MainActor
    init(viewModel: MempoolViewModel? = nil, networkStatsViewModel: NetworkStatsViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: MempoolViewModel(mempoolService: MempoolSpaceService()))
        }

        if let networkStatsViewModel = networkStatsViewModel {
            _networkStatsViewModel = StateObject(wrappedValue: networkStatsViewModel)
        } else {
            _networkStatsViewModel = StateObject(wrappedValue: NetworkStatsViewModel())
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                themeManager.contentViewBackgroundColor
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            showingDevelopersView = true
                        } label: {
                            Image("AppIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: Constants.appIconSize, height: Constants.appIconSize)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.appleTV)

                        Spacer()

                        FeesPriorityWidget(feeEstimate: networkStatsViewModel.feeEstimate, btcPrice: networkStatsViewModel.priceResponse?.USD)

                        Spacer()

                        NavigationLink(value: "NetworkStatistics") {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                Text("Stats")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.appleTV)
                        .padding(.trailing, 20)

                        BitcoinPriceView(priceResponse: networkStatsViewModel.priceResponse)
                            .padding(.trailing, 20)
                    }
                    .padding(.horizontal, 1)
                    .padding(.top, 5)
                    .padding(.bottom, 1)

                    if viewModel.isLoadingAny {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        if let error = viewModel.confirmedBlocksState.errorMessage {
                            errorBanner(error)
                        }
                        if let error = viewModel.mempoolTransactionsState.errorMessage {
                            errorBanner(error)
                        }
                        if let error = viewModel.blockAverageFeesState.errorMessage {
                            errorBanner(error)
                        }

                        VStack(spacing: 0) {
                            BlockTimelineView(viewModel: viewModel)

                            if let selectedBlock = viewModel.selectedBlock {
                                BlockDetailView(selectedBlock: selectedBlock, mempoolService: viewModel.mempoolService)
                                    .padding(.top, 10)
                            } else {
                                VStack {
                                    Spacer()
                                    Text("Select a block to view details")
                                        .font(.title2)
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }

                    Spacer()
                }
                .onAppear {
                    viewModel.startPolling()
                    networkStatsViewModel.startAutoRefresh()
                }
                .onDisappear {
                    viewModel.stopPolling()
                    networkStatsViewModel.stopAutoRefresh()
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "NetworkStatistics" {
                    NetworkStatisticsView()
                        .environmentObject(themeManager)
                        .environmentObject(networkStatsViewModel)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .sheet(isPresented: $showingDevelopersView) {
            DevelopersView()
                .environmentObject(themeManager)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Text("Error: \(message)")
            .foregroundColor(.red)
            .padding(.horizontal)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.6))
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
