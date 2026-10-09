import SwiftUI

@MainActor
final class DossierModel: ObservableObject {
    @Published var detail: ChainBlock
    @Published var metadataError: String?
    @Published var transactions: [Transaction] = []
    @Published var transactionError: String?
    @Published var loading = false
    @Published var complete = false
    private var nextIndex = 0
    let api: TelemetryAPI
    init(block: ChainBlock, api: TelemetryAPI) { detail = block; self.api = api }
    func metadata() async {
        do {
            let result: ChainBlock = try await api.get("v1/block/\(detail.id)")
            try Task.checkCancellation(); detail = result; metadataError = nil
        } catch { if !Task.isCancelled { metadataError = error.localizedDescription } }
    }
    func nextPage() async {
        guard !loading, !complete else { return }
        loading = true; transactionError = nil
        defer { loading = false }
        do {
            let page: [Transaction] = try await api.get("block/\(detail.id)/txs/\(nextIndex)")
            try Task.checkCancellation()
            nextIndex += page.count
            let known = Set(transactions.map(\.id))
            transactions += page.filter { !$0.vin.contains(where: \.isCoinbase) && !known.contains($0.id) }
            complete = page.count < 25 || nextIndex >= detail.tx_count
        } catch { if !Task.isCancelled { transactionError = error.localizedDescription } }
    }
}
struct BlockDossier: View {
    @StateObject private var model: DossierModel
    @Environment(\.dismiss) private var dismiss
    init(block: ChainBlock, api: TelemetryAPI) { _model = StateObject(wrappedValue: DossierModel(block: block, api: api)) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    ScreenHeading(eyebrow: "THE BLOCK DOSSIER", title: "Block \(model.detail.height.formatted())", tint: ObservatoryStyle.orange)
                    Button("Back · Close") { dismiss() }.buttonStyle(ObservatoryButtonStyle())
                }
                Text(model.detail.id).font(.system(size: 25, design: .monospaced))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3), spacing: 24) {
                    fact("POOL", model.detail.extras?.pool?.name ?? "Unavailable")
                    fact("TRANSACTIONS", model.detail.tx_count.formatted())
                    fact("VIRTUAL SIZE", metric(model.detail.vsize, digits: 2, suffix: " vB"))
                    fact("TOTAL FEES", metric(model.detail.extras?.totalFees.map { $0 / 1e8 }, digits: 8, suffix: " BTC"))
                    fact("PROTOCOL SUBSIDY", metric(model.detail.subsidy, digits: 8, suffix: " BTC"))
                    fact("COINBASE REWARD · INCLUDES FEES", metric(model.detail.extras?.reward.map { $0 / 1e8 }, digits: 8, suffix: " BTC"))
                    fact("MEDIAN FEE RATE", metric(model.detail.extras?.medianFee, digits: 2, suffix: " sat/vB"))
                    fact("WEIGHT UTILIZATION", metric(Double(model.detail.weight) / 4e6 * 100, digits: 2, suffix: "%"))
                    fact("HEADER TIMESTAMP", Date(timeIntervalSince1970: Double(model.detail.timestamp)).formatted(date: .abbreviated, time: .standard))
                }
                Text("Provider first-seen: " + (model.detail.extras?.firstSeen.flatMap { $0 > 0 ? Date(timeIntervalSince1970: $0).formatted(date: .abbreviated, time: .standard) : nil } ?? "Unavailable"))
                    .foregroundStyle(ObservatoryStyle.secondary)
                if let error = model.metadataError { Text("Metadata unavailable · \(error)").foregroundStyle(ObservatoryStyle.stale) }
                Button("Refresh block metadata") { Task { await model.metadata() } }.buttonStyle(ObservatoryButtonStyle())
                Text("TRANSACTIONS · BLOCK ORDER").font(.system(size: 28, weight: .semibold))
                Text("Coinbase excluded. Output value includes change; it is not economic value transferred. Pages are not a whole-block top-ten ranking.")
                    .font(.system(size: 24)).foregroundStyle(ObservatoryStyle.secondary)
                ForEach(model.transactions) { tx in
                    HStack {
                        Text(String(tx.txid.prefix(24)) + "…").font(.system(size: 24, design: .monospaced))
                        Spacer()
                        Text(metric(tx.totalOutputBTC, digits: 6, suffix: " BTC outputs"))
                        Text(metric(Double(tx.fee) / (Double(tx.weight) / 4), digits: 2, suffix: " sat/vB"))
                    }.font(.system(size: 25)).padding(20).background(ObservatoryStyle.card, in: RoundedRectangle(cornerRadius: 12))
                }
                if let error = model.transactionError { Text("Transactions unavailable · \(error)").foregroundStyle(ObservatoryStyle.stale) }
                if !model.complete {
                    Button(model.loading ? "Loading…" : model.transactionError == nil ? "Load next page" : "Retry page") { Task { await model.nextPage() } }
                        .buttonStyle(ObservatoryButtonStyle()).disabled(model.loading)
                }
            }.padding(70)
        }.background(ObservatoryStyle.canvas).foregroundStyle(ObservatoryStyle.text)
            .task { await model.metadata(); await model.nextPage() }
            .onExitCommand { dismiss() }
    }
    private func fact(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.system(size: 21)).foregroundStyle(ObservatoryStyle.secondary)
            Text(value).font(.system(size: 32, weight: .medium)).monospacedDigit().minimumScaleFactor(0.7)
        }.frame(maxWidth: .infinity, minHeight: 90, alignment: .leading).observatoryCard()
    }
}
