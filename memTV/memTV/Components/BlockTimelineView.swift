//
//  BlockTimelineView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import SwiftUI

struct BlockTimelineView: View {
    @ObservedObject var viewModel: MempoolViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                // Mempool blocks (pending/future)
                ForEach(Array(viewModel.mempoolTransactions.sorted { $0.position < $1.position }.enumerated()).prefix(Constants.blockDisplayCount), id: \.element.txid) { _, transaction in
                    let displayNumber = transaction.txid.prefix(8).hashValue % 100000
                    let mempoolBlockCount = viewModel.mempoolTransactions.count
                    let estimatedTime = (mempoolBlockCount - transaction.position) * Constants.blockDurationMinutes

                    Button {
                        viewModel.selectBlock(.mempool(transaction))
                    } label: {
                        BlockView(
                            blockNumber: displayNumber,
                            isConfirmed: false,
                            feeInfo: FeeInfo(
                                estimatedMinutes: estimatedTime,
                                medianFee: transaction.medianFee
                            ),
                            isSelected: isSelected(transaction)
                        )
                    }
                    .buttonStyle(.appleTV)
                }

                // Separator
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: 100)
                    .padding(.horizontal, 10)

                // Confirmed blocks
                ForEach(viewModel.confirmedBlocks, id: \.hash) { block in
                    Button {
                        viewModel.selectBlock(.confirmed(block))
                    } label: {
                        BlockView(
                            blockNumber: block.height,
                            isConfirmed: true,
                            feeInfo: FeeInfo(
                                averageFee: viewModel.blockAverageFees[block.hash]
                            ),
                            isSelected: isSelected(block)
                        )
                    }
                    .buttonStyle(.appleTV)
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxHeight: 250)
        .padding(.vertical, 10)
    }

    private func isSelected(_ block: Block) -> Bool {
        if case .confirmed(let selected) = viewModel.selectedBlock {
            return selected.hash == block.hash
        }
        return false
    }

    private func isSelected(_ transaction: MempoolTransaction) -> Bool {
        if case .mempool(let selected) = viewModel.selectedBlock {
            return selected.txid == transaction.txid
        }
        return false
    }
}
