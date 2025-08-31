//
//  ContentView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MempoolViewModel()
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Title
                Text("Bitcoin Mempool Viewer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                // Loading indicator
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    ScrollView {
                        // Mempool Blocks Section (moved above)
                        VStack {
                            Text("Mempool Transactions")
                                .font(.title2)
                                .foregroundColor(.purple)
                                .padding(.bottom, 10)
                            
                            // List of mempool transactions
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 5), spacing: 20) {
                                ForEach(viewModel.mempoolTransactions, id: \.self) { txId in
                                    BlockView(blockNumber: txId.prefix(8).hashValue % 100000, isConfirmed: false)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        
                        // Confirmed Blocks Section (now below)
                        VStack {
                            Text("Confirmed Blocks (Last 5)")
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .padding(.bottom, 10)
                            
                            // Grid of confirmed blocks
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 5), spacing: 20) {
                                ForEach(viewModel.confirmedBlocks, id: \.hash) { block in
                                    BlockView(blockNumber: block.height, isConfirmed: true)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                    }
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                viewModel.startPolling()
            }
        }
    }
}

#Preview {
    ContentView()
}
