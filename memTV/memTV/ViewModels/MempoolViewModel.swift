//
//  MempoolViewModel.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation
import SwiftUI

@MainActor
class MempoolViewModel: ObservableObject {
    @Published var confirmedBlocks: [Block] = []
    @Published var mempoolTransactions: [MempoolTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedBlock: SelectedBlockType?
    @Published var blockAverageFees: [String: Int] = [:]

    private var persistentSelection: PersistentSelection = .none
    private let mempoolService: MempoolSpaceService
    private var timer: Timer?

    init(mempoolService: MempoolSpaceService = MempoolSpaceService()) {
        self.mempoolService = mempoolService
    }

    func startPolling() {
        loadMempoolData()

        timer = Timer.scheduledTimer(withTimeInterval: Constants.pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.loadMempoolData()
            }
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func loadMempoolData() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await loadConfirmedBlocks()
                try await loadBlockAverageFees()
                try await loadMempoolTransactions()

                isLoading = false
                restoreSelection()
            } catch {
                isLoading = false
                errorMessage = "Failed to load data: \(error.localizedDescription)"
            }
        }
    }

    private func loadConfirmedBlocks() async throws {
        let blocks = try await mempoolService.getRecentBlocks()
        self.confirmedBlocks = blocks
    }

    private func loadMempoolTransactions() async throws {
        let transactions = try await mempoolService.getRecentMempoolTransactions()
        self.mempoolTransactions = transactions
    }

    private func loadBlockAverageFees() async throws {
        var averageFees: [String: Int] = [:]

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
            if let block = confirmedBlocks.first(where: { $0.hash == hash }) {
                selectedBlock = .confirmed(block)
            } else {
                clearSelection()
            }

        case .mempoolBlock(let position):
            if let transaction = mempoolTransactions.first(where: { $0.position == position }) {
                selectedBlock = .mempool(transaction)
            } else {
                clearSelection()
            }

        case .none:
            break
        }
    }

    deinit {
        timer?.invalidate()
    }
}
