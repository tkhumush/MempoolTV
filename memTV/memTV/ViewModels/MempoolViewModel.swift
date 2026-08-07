//
//  MempoolViewModel.swift
//  memTV
//
//  Main UI state management with cancellable async polling and per-section errors.
//

import Foundation
import SwiftUI

@MainActor
final class MempoolViewModel: ObservableObject {
    @Published var confirmedBlocksState: LoadableState<[Block]> = .idle
    @Published var mempoolTransactionsState: LoadableState<[MempoolTransaction]> = .idle
    @Published var blockAverageFeesState: LoadableState<[String: Int]> = .idle
    @Published var selectedBlock: SelectedBlockType?

    var confirmedBlocks: [Block] { confirmedBlocksState.value ?? [] }
    var mempoolTransactions: [MempoolTransaction] { mempoolTransactionsState.value ?? [] }
    var blockAverageFees: [String: Int] { blockAverageFeesState.value ?? [:] }

    var isLoadingAny: Bool {
        confirmedBlocksState.isLoading || mempoolTransactionsState.isLoading || blockAverageFeesState.isLoading
    }

    var hasAnyError: Bool {
        confirmedBlocksState.errorMessage != nil || mempoolTransactionsState.errorMessage != nil || blockAverageFeesState.errorMessage != nil
    }

    private var persistentSelection: PersistentSelection = .none
    let mempoolService: MempoolSpaceService
    private var pollingTask: Task<Void, Never>?

    init(mempoolService: MempoolSpaceService) {
        self.mempoolService = mempoolService
    }

    func startPolling() {
        stopPolling()
        pollingTask = Task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Constants.pollingInterval * 1_000_000_000))
                guard !Task.isCancelled else { break }
                await refresh()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh() async {
        async let confirmedTask: () = loadConfirmedBlocks()
        async let mempoolTask: () = loadMempoolTransactions()

        await confirmedTask
        await mempoolTask

        if case .loaded = confirmedBlocksState {
            await loadBlockAverageFees()
        }

        restoreSelection()
    }

    private func loadConfirmedBlocks() async {
        confirmedBlocksState = .loading
        do {
            let blocks = try await mempoolService.getRecentBlocks()
            confirmedBlocksState = .loaded(blocks)
        } catch {
            confirmedBlocksState = .failed("Failed to load confirmed blocks: \(error.localizedDescription)")
        }
    }

    private func loadMempoolTransactions() async {
        mempoolTransactionsState = .loading
        do {
            let transactions = try await mempoolService.getRecentMempoolTransactions()
            mempoolTransactionsState = .loaded(transactions)
        } catch {
            mempoolTransactionsState = .failed("Failed to load mempool: \(error.localizedDescription)")
        }
    }

    private func loadBlockAverageFees() async {
        let blocks = confirmedBlocks
        guard !blocks.isEmpty else {
            blockAverageFeesState = .loaded([:])
            return
        }

        blockAverageFeesState = .loading
        var averageFees: [String: Int] = [:]
        var errors: [String] = []

        let service = mempoolService
        await withTaskGroup(of: (hash: String, fee: Int?).self) { group in
            for block in blocks {
                let blockHash = block.hash
                group.addTask {
                    do {
                        let fee = try await service.getBlockAverageFee(blockHash: blockHash)
                        return (blockHash, fee)
                    } catch {
                        return (blockHash, nil)
                    }
                }
            }

            for await result in group {
                if let fee = result.fee {
                    averageFees[result.hash] = fee
                } else {
                    errors.append(result.hash)
                }
            }
        }

        if averageFees.isEmpty, !errors.isEmpty {
            blockAverageFeesState = .failed("Could not fetch average fees for any block.")
        } else {
            blockAverageFeesState = .loaded(averageFees)
        }
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
        stopPolling()
    }
}
