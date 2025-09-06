import SwiftUI
import Charts

// MARK: - Data Model
struct TransactionData: Identifiable {
    let id = UUID()
    let amount: Double // Amount in BTC
    let txid: String   // Transaction ID (shortened)
    let fee: Double    // Fee in sats/vB
    
    var formattedAmount: String {
        return String(format: "%.3f BTC", amount)
    }
    
    var shortTxid: String {
        return String(txid.prefix(8)) + "..."
    }
}

// MARK: - Top Transactions Chart
struct TopTransactionsChart: View {
    let transaction: MempoolTransaction
    let chartHeight: CGFloat = 200
    
    private var topTransactions: [TransactionData] {
        generateMockTransactionData(for: transaction)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Top 10 Largest Transactions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Largest transactions by BTC amount in this block")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if topTransactions.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: chartHeight)
                    .overlay(
                        Text("No transaction data available")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
            } else {
                Chart(topTransactions) { transaction in
                    BarMark(
                        x: .value("Amount", transaction.amount),
                        y: .value("Transaction", transaction.shortTxid)
                    )
                    .foregroundStyle(colorForTransaction(transaction))
                    .cornerRadius(4)
                    .accessibilityLabel("Transaction \(transaction.shortTxid)")
                    .accessibilityValue("\(transaction.formattedAmount)")
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
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func colorForTransaction(_ transaction: TransactionData) -> Color {
        // Color based on transaction amount
        if transaction.amount >= 10.0 {
            return .orange        // Very large transactions (10+ BTC)
        } else if transaction.amount >= 5.0 {
            return .yellow        // Large transactions (5-10 BTC)
        } else if transaction.amount >= 1.0 {
            return .green         // Medium transactions (1-5 BTC)
        } else {
            return .blue          // Smaller transactions (< 1 BTC)
        }
    }
    
    private func generateMockTransactionData(for mempoolTransaction: MempoolTransaction) -> [TransactionData] {
        // Generate realistic mock transaction data based on mempool block characteristics
        let baseAmount = Double(mempoolTransaction.totalFees) / 100_000_000.0 // Convert sats to BTC
        let txCount = min(mempoolTransaction.nTx, 10) // Top 10 or fewer if block has less
        
        var transactions: [TransactionData] = []
        
        // Generate transactions with decreasing amounts (largest first)
        for i in 0..<min(txCount, 10) {
            let randomMultiplier = Double.random(in: 0.5...3.0)
            let amount = max(baseAmount * randomMultiplier * Double(10 - i), 0.001)
            
            let mockTxid = String(format: "%08x", Int.random(in: 100000000...999999999))
            let fee = Double(mempoolTransaction.medianFee) * (1.0 + Double.random(in: -0.3...0.8))
            
            transactions.append(TransactionData(
                amount: amount,
                txid: mockTxid,
                fee: max(fee, 1.0)
            ))
        }
        
        // Sort by amount descending to show largest first
        return transactions.sorted { $0.amount > $1.amount }
    }
}

// MARK: - Preview
#Preview {
    let mockTransaction = MempoolTransaction(
        txid: "mock_txid",
        fee: 5000,
        vsize: 250,
        position: 0,
        estimatedConfirmationTime: 15,
        medianFee: 25,
        blockSize: 1000000,
        blockVSize: 800000,
        nTx: 150,
        totalFees: 12500000
    )
    
    return TopTransactionsChart(transaction: mockTransaction)
        .background(Color.black)
        .previewLayout(.sizeThatFits)
}