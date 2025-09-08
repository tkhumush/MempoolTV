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
    case mempool(MempoolTransaction) // Full transaction data
}

// MARK: - Selection Persistence
enum PersistentSelection: Equatable {
    case confirmedBlock(hash: String)
    case mempoolBlock(position: Int)
    case none
}

@MainActor
class MempoolViewModel: ObservableObject {
    @Published var confirmedBlocks: [Block] = []
    @Published var mempoolTransactions: [MempoolTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedBlock: SelectedBlockType?
    
    // Selection persistence
    private var persistentSelection: PersistentSelection = .none
    
    // Fee data
    @Published var feeRecommendations: (high: Int, medium: Int, low: Int, estimatedMinutes: Int) = (45, 30, 15, 30)
    @Published var blockAverageFees: [String: Int] = [:] // blockHash -> averageFee
    
    private let mempoolService: MempoolSpaceService
    private var timer: Timer?
    
    init(mempoolService: MempoolSpaceService = MempoolSpaceService()) {
        self.mempoolService = mempoolService
    }
    
    // Start polling for updates
    func startPolling() {
        loadMempoolData()
        
        // Set up a timer to refresh every 60 seconds (Bitcoin blocks average ~10 minutes)
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
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
                // Get fee recommendations first
                try await loadFeeRecommendations()
                
                // Get the latest confirmed blocks (last 10)
                try await loadConfirmedBlocks()
                
                // Get average fees for confirmed blocks
                try await loadBlockAverageFees()
                
                // Get mempool transactions
                try await loadMempoolTransactions()
                
                isLoading = false
                
                // Restore selection after data refresh
                restoreSelection()
                
                // Log API usage statistics
                mempoolService.logAPIUsage()
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
        self.mempoolTransactions = transactions
    }
    
    // Load fee recommendations
    private func loadFeeRecommendations() async throws {
        let fees = try await mempoolService.getFeeRecommendations()
        self.feeRecommendations = fees
    }
    
    // Load average fees for confirmed blocks
    private func loadBlockAverageFees() async throws {
        var averageFees: [String: Int] = [:]
        
        // Get average fee for each confirmed block
        for block in confirmedBlocks {
            if let avgFee = try? await mempoolService.getBlockAverageFee(blockHash: block.hash) {
                averageFees[block.hash] = avgFee
            }
        }
        
        self.blockAverageFees = averageFees
    }
    
    // MARK: - Selection Methods
    func selectBlock(_ blockType: SelectedBlockType) {
        selectedBlock = blockType
        
        // Update persistent selection
        switch blockType {
        case .confirmed(let block):
            persistentSelection = .confirmedBlock(hash: block.hash)
        case .mempool(let transaction):
            persistentSelection = .mempoolBlock(position: transaction.position)
        }
    }
    
    func clearSelection() {
        selectedBlock = nil
        persistentSelection = .none
    }
    
    // MARK: - Selection Persistence
    private func restoreSelection() {
        switch persistentSelection {
        case .confirmedBlock(let hash):
            // Find the confirmed block with matching hash
            if let block = confirmedBlocks.first(where: { $0.hash == hash }) {
                selectedBlock = .confirmed(block)
            } else {
                // Block no longer exists, clear selection
                clearSelection()
            }
            
        case .mempoolBlock(let position):
            // Find the mempool transaction with matching position
            if let transaction = mempoolTransactions.first(where: { $0.position == position }) {
                selectedBlock = .mempool(transaction)
            } else {
                // Position no longer exists, clear selection
                clearSelection()
            }
            
        case .none:
            // No selection to restore
            break
        }
    }
    
    deinit {
        Task { @MainActor in
            self.stopPolling()
        }
    }
}
