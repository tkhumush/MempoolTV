//
//  ContentView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MempoolViewModel()
    @State private var showingDevelopersView = false
    
    var body: some View {
        ZStack {
            // Custom blue background (#3399CC)
            Color(red: 51/255, green: 153/255, blue: 204/255)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with logo
                HStack {
                    // App icon logo - now a button
                    Button {
                        showingDevelopersView = true
                    } label: {
                        Image("AppIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.appleTV)

                    Spacer()

                    // Bitcoin price in top right corner
                    BitcoinPriceView()
                        .padding(.trailing, 20)
                }
                .padding(.horizontal, 1)
                .padding(.top, 5)
                .padding(.bottom, 1)
                
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
                    
                    VStack(spacing: 0) {
                        // Timeline layout - top one-third
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                // Mempool transactions first (representing pending/future)
                                // Sort by position: lower position numbers (closest to confirmation) on the right
                                ForEach(Array(viewModel.mempoolTransactions.sorted { $0.position < $1.position }.enumerated()).prefix(8), id: \.element.txid) { index, transaction in
                                    let displayNumber = transaction.txid.prefix(8).hashValue % 100000
                                    let blockDuration = 10
                                    let mempoolBlockCount = viewModel.mempoolTransactions.count
                                    let estimatedTime = (mempoolBlockCount - transaction.position) * blockDuration
                                    
                                    Button {
                                        viewModel.selectBlock(.mempool(transaction))
                                    } label: {
                                        BlockView(
                                            blockNumber: displayNumber,
                                            isConfirmed: false,
                                            feeInfo: FeeInfo(
                                                highPriority: 0,
                                                mediumPriority: 0,
                                                lowPriority: 0,
                                                estimatedMinutes: estimatedTime,
                                                averageFee: nil,
                                                medianFee: transaction.medianFee
                                            ),
                                            isSelected: isBlockSelected(txId: transaction.txid, displayNumber: displayNumber),
                                            onTap: { }
                                        )
                                    }
                                    .buttonStyle(.appleTV)
                                }
                                
                                // Visual separator between mempool and confirmed
                                Rectangle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 2, height: 100)
                                    .padding(.horizontal, 10)
                                
                                // Confirmed blocks (representing established timeline)
                                ForEach(viewModel.confirmedBlocks, id: \.hash) { block in
                                    Button {
                                        viewModel.selectBlock(.confirmed(block))
                                    } label: {
                                        BlockView(
                                            blockNumber: block.height,
                                            isConfirmed: true,
                                            feeInfo: FeeInfo(
                                                highPriority: 0,
                                                mediumPriority: 0,
                                                lowPriority: 0,
                                                estimatedMinutes: 0,
                                                averageFee: viewModel.blockAverageFees[block.hash]
                                            ),
                                            isSelected: isBlockSelected(block: block),
                                            onTap: { }
                                        )
                                    }
                                    .buttonStyle(.appleTV)
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                        .frame(maxHeight: 250)
                        .padding(.vertical, 10)
                        
                        // Block details section - bottom two-thirds
                        if let selectedBlock = viewModel.selectedBlock {
                            BlockDetailView(selectedBlock: selectedBlock)
                                .padding(.top, 10)
                        } else {
                            VStack {
                                Spacer()
                                Text("Select a block to view details")
                                    .font(.title2)
                                    .foregroundColor(.gray)
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
        .sheet(isPresented: $showingDevelopersView) {
            DevelopersView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func isBlockSelected(block: Block) -> Bool {
        switch viewModel.selectedBlock {
        case .confirmed(let selectedBlock):
            return selectedBlock.hash == block.hash
        case .mempool(_):
            return false
        case .none:
            return false
        }
    }
    
    private func isBlockSelected(txId: String, displayNumber: Int) -> Bool {
        switch viewModel.selectedBlock {
        case .mempool(let selectedTransaction):
            return selectedTransaction.txid == txId
        case .confirmed(_):
            return false
        case .none:
            return false
        }
    }
}

// MARK: - CardButtonStyle for Apple TV

extension ButtonStyle where Self == CardButtonStyle {
    static var appleTV: CardButtonStyle {
        CardButtonStyle()
    }
}

struct CardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.05 : 1.0))
            .shadow(color: isFocused ? .white : .clear, radius: isFocused ? 8 : 0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    ContentView()
}
