//
//  MempoolViewModel.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation
import SwiftUI

// MARK: - Selection Types
enum SelectedBlockType {
    case confirmed(Block)
    case mempool(String, Int) // txId, displayNumber
}

@MainActor
class MempoolViewModel: ObservableObject {
    @Published var confirmedBlocks: [Block] = []
    @Published var mempoolTransactions: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedBlock: SelectedBlockType?
    
    private let mempoolService: MempoolSpaceService
    private var timer: Timer?
    
    init(mempoolService: MempoolSpaceService = MempoolSpaceService()) {
        self.mempoolService = mempoolService
    }
    
    // Start polling for updates
    func startPolling() {
        loadMempoolData()
        
        // Set up a timer to refresh every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.loadMempoolData()
            }
        }
    }
    
    // Stop polling
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    // Load mempool data
    func loadMempoolData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get the latest confirmed blocks (last 10)
                try await loadConfirmedBlocks()
                
                // Get mempool transactions
                try await loadMempoolTransactions()
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to load data: \(error.localizedDescription)"
                print("Error loading mempool data: \(error)")
            }
        }
    }
    
    // Load the last 10 confirmed blocks
    private func loadConfirmedBlocks() async throws {
        let blocks = try await mempoolService.getRecentBlocks()
        self.confirmedBlocks = blocks
    }
    
    // Load mempool transactions
    private func loadMempoolTransactions() async throws {
        let transactions = try await mempoolService.getRecentMempoolTransactions()
        self.mempoolTransactions = transactions.map { $0.txid }
    }
    
    // MARK: - Selection Methods
    func selectBlock(_ blockType: SelectedBlockType) {
        selectedBlock = blockType
    }
    
    func clearSelection() {
        selectedBlock = nil
    }
    
    deinit {
        Task { @MainActor in
            self.stopPolling()
        }
    }
}
