//
//  BlockTimelineView.swift
//  memTV
//
//  Horizontal scrollable timeline of pending and confirmed blocks.
//

import SwiftUI

struct BlockTimelineView: View {
    @ObservedObject var viewModel: MempoolViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                // Mempool blocks (pending/future)
                ForEach(viewModel.mempoolTransactions) { transaction in
                    let estimatedTime = (viewModel.mempoolTransactions.count - transaction.position) * Constants.blockDurationMinutes

                    Button {
                        viewModel.selectBlock(.mempool(transaction))
                    } label: {
                        BlockView(
                            blockNumber: transaction.position,
                            isConfirmed: false,
                            feeInfo: FeeInfo(
                                estimatedMinutes: estimatedTime,
                                medianFee: transaction.medianFee
                            ),
                            isSelected: isSelected(transaction)
                        )
                    }
                    .buttonStyle(.appleTV)
                    .accessibilityLabel("Mempool block \(transaction.displayLabel), median fee \(transaction.medianFee) satoshis per virtual byte, estimated confirmation in \(estimatedTime) minutes")
                }

                // Separator
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: 100)
                    .padding(.horizontal, 10)

                // Confirmed blocks
                ForEach(viewModel.confirmedBlocks) { block in
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
                    .accessibilityLabel("Confirmed block \(block.height), mined by \(block.miner ?? "unknown pool")")
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
            return selected.position == transaction.position
        }
        return false
    }
}
