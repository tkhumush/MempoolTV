//
//  TopTransactionsViewModel.swift
//  memTV
//
//  Fetches real per-transaction data from mempool.space for the selected mempool block.
//

import Foundation

@MainActor
final class TopTransactionsViewModel: ObservableObject {
    @Published var transactionsState: LoadableState<[Transaction]> = .idle

    var transactions: [Transaction] { transactionsState.value ?? [] }

    private let mempoolService: MempoolSpaceService

    init(mempoolService: MempoolSpaceService) {
        self.mempoolService = mempoolService
    }

    func loadTopTransactions(from transaction: MempoolTransaction) async {
        transactionsState = .loading

        // The selected "mempool block" in this app is a projected block, not a real confirmed
        // block with a hash.  We therefore cannot list its actual transactions.  To still provide
        // meaningful real data, fetch the most recently confirmed block's transactions and rank
        // them by BTC amount, which is the closest available proxy for "large transactions".
        do {
            let blocks = try await mempoolService.getRecentBlocks(limit: 1)
            guard let latestBlock = blocks.first else {
                transactionsState = .failed("No confirmed blocks available to inspect transactions.")
                return
            }

            let txs = try await mempoolService.getTransactions(forBlockHash: latestBlock.hash)
            let top = txs
                .sorted { $0.totalOutputValue > $1.totalOutputValue }
                .prefix(10)

            transactionsState = .loaded(Array(top))
        } catch {
            transactionsState = .failed("Failed to load transactions: \(error.localizedDescription)")
        }
    }
}
