//
//  TopTransactionsChart.swift
//  memTV
//
//  Horizontal bar chart of real top transactions by BTC amount.
//

import SwiftUI
import Charts

struct TopTransactionsChart: View {
    let transaction: MempoolTransaction
    @StateObject private var viewModel: TopTransactionsViewModel
    let chartHeight: CGFloat = 490

    @MainActor
    init(transaction: MempoolTransaction, mempoolService: MempoolSpaceService) {
        self.transaction = transaction
        _viewModel = StateObject(wrappedValue: TopTransactionsViewModel(mempoolService: mempoolService))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Top 10 largest transactions by BTC amount in the latest confirmed block")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            switch viewModel.transactionsState {
            case .loading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: chartHeight)
                    .overlay(
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    )
            case .loaded(let transactions):
                if transactions.isEmpty {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: chartHeight)
                        .overlay(
                            Text("No transaction data available")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                } else {
                    Chart(transactions) { transaction in
                        BarMark(
                            x: .value("Amount", transaction.totalOutputBTC),
                            y: .value("Transaction", transaction.shortTxid)
                        )
                        .foregroundStyle(colorForTransaction(transaction))
                        .cornerRadius(4)
                        .accessibilityLabel("Transaction \(transaction.shortTxid)")
                        .accessibilityValue("\(String(format: "%.3f BTC", transaction.totalOutputBTC))")
                    }
                    .frame(height: chartHeight)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                .foregroundStyle(Color.secondary.opacity(0.3))
                            AxisTick()
                                .foregroundStyle(Color.gray)
                            AxisValueLabel()
                                .font(.system(size: 10))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .font(.system(size: 9))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Top \(transactions.count) largest transactions by BTC amount")
                }
            case .idle:
                EmptyView()
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .task {
            await viewModel.loadTopTransactions(from: transaction)
        }
    }

    private func colorForTransaction(_ transaction: Transaction) -> Color {
        if transaction.totalOutputBTC >= 10.0 {
            return .orange
        } else if transaction.totalOutputBTC >= 5.0 {
            return .yellow
        } else if transaction.totalOutputBTC >= 1.0 {
            return .green
        } else {
            return .blue
        }
    }
}
