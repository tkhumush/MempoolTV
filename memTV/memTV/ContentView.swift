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
    @StateObject private var viewModel = MempoolViewModel()
    @StateObject private var themeManager = ThemeManager()
    @State private var showingDevelopersView = false
    @State private var navigationPath = NavigationPath()

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

                        FeesPriorityWidget()

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

                        BitcoinPriceView()
                            .padding(.trailing, 20)
                    }
                    .padding(.horizontal, 1)
                    .padding(.top, 5)
                    .padding(.bottom, 1)

                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        if let errorMessage = viewModel.errorMessage {
                            Text("Error: \(errorMessage)")
                                .foregroundColor(.red)
                                .padding()
                        }

                        VStack(spacing: 0) {
                            BlockTimelineView(viewModel: viewModel)

                            if let selectedBlock = viewModel.selectedBlock {
                                BlockDetailView(selectedBlock: selectedBlock)
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
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "NetworkStatistics" {
                    NetworkStatisticsView()
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .sheet(isPresented: $showingDevelopersView) {
            DevelopersView(themeManager: themeManager)
        }
    }
}

#Preview {
    ContentView()
}
