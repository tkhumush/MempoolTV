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
            
            VStack(spacing: 0) {
                // Header with logo and app name
                HStack {
                    // Logo placeholder (using a styled rectangle for now)
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("TV")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        )
                    
                    Text("memTV")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                .padding(.bottom, 30)
                
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
                    
                    // Timeline layout - all blocks in one horizontal scrollable line
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            // Mempool transactions first (representing pending/future)
                            ForEach(Array(viewModel.mempoolTransactions.prefix(8).enumerated()), id: \.element) { index, txId in
                                BlockView(
                                    blockNumber: txId.prefix(8).hashValue % 100000, 
                                    isConfirmed: false,
                                    transactionCount: nil
                                )
                            }
                            
                            // Visual separator between mempool and confirmed
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 2, height: 100)
                                .padding(.horizontal, 10)
                            
                            // Confirmed blocks (representing established timeline)
                            ForEach(viewModel.confirmedBlocks.reversed(), id: \.hash) { block in
                                BlockView(
                                    blockNumber: block.height, 
                                    isConfirmed: true,
                                    transactionCount: block.txCount
                                )
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 20)
                }
                
                Spacer()
            }
            .onAppear {
                viewModel.startPolling()
            }
        }
    }
}

#Preview {
    ContentView()
}
