import SwiftUI

struct OverviewScreen: View {
    @ObservedObject var model: ObservatoryModel
    let focus: FocusState<String?>.Binding
    var body: some View {
        VStack(spacing: 12) {
            ScreenHeading(eyebrow: "THE BITCOIN OBSERVATORY", title: "Never stops. Neither do we.", note: "Network in motion\nEstimates are not a schedule")
            HStack {
                Text("← CONFIRMED CHAIN").foregroundStyle(ObservatoryStyle.orange)
                Spacer(); Text("NOW"); Spacer()
                Text("PROJECTED BLOCKS →  ·  ESTIMATES").foregroundStyle(ObservatoryStyle.violet)
            }.font(.system(size: 22, weight: .medium)).tracking(2)
            HStack(spacing: 20) {
                if let blocks = model.blocks.value, !blocks.isEmpty {
                    ForEach(Array(blocks.prefix(3).reversed())) { block in
                        Button { model.input(); model.dossier = block } label: {
                            blockTile(block)
                        }.buttonStyle(ObservatoryButtonStyle()).focused(focus, equals: block.id)
                    }
                } else { emptyWall("Confirmed chain unavailable") }
                Rectangle().fill(ObservatoryStyle.teal).frame(width: 2, height: 180).shadow(color: ObservatoryStyle.teal, radius: 12)
                if let values = model.projections.value, !values.isEmpty {
                    ForEach(Array(values.prefix(3).enumerated()), id: \.offset) { index, block in
                        Button { model.select(.fees) } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(index == 0 ? "NEXT" : "+\(index) BLOCK").font(.system(size: 22)).foregroundStyle(ObservatoryStyle.violet)
                                Text(metric(block.medianFee, digits: 2)).font(.system(size: 42, weight: .semibold)).monospacedDigit()
                                Text("Median · sat/vB").font(.system(size: 21))
                                Text("\(block.nTx.formatted()) tx").font(.system(size: 22))
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(18).frame(height: 190)
                                .background(LinearGradient(colors: [ObservatoryStyle.violet.opacity(0.24), ObservatoryStyle.card], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ObservatoryStyle.violet.opacity(0.5)))
                        }.buttonStyle(ObservatoryButtonStyle())
                    }
                } else { emptyWall("Projections unavailable") }
            }
            HStack(spacing: 35) {
                ObservationStatus(observation: model.blocks, maxAge: 1800) { model.retryLive() }
                ObservationStatus(observation: model.projections) { Task { await model.refresh(slow: false) } }
            }
            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    HeroMetric(title: "NEXT-BLOCK FEE", value: metric(model.fees.value?.fastestFee, digits: 2), unit: "sat/vB", caption: "Recommendation · confirmation is not guaranteed")
                    ObservationStatus(observation: model.fees) { Task { await model.refresh(slow: false) } }
                }.observatoryCard()
                VStack(alignment: .leading, spacing: 12) {
                    HeroMetric(title: "BITCOIN / USD", value: model.price.value.map { "$" + metric($0.USD, digits: 0) } ?? "Unavailable", caption: priceChange)
                    ObservationStatus(observation: model.price, maxAge: 3600) { Task { await model.refreshPrice() } }
                    if model.priceHistory.error != nil { Text("24h comparison unavailable").font(.system(size: 19)).foregroundStyle(ObservatoryStyle.stale) }
                }.observatoryCard()
                VStack(alignment: .leading, spacing: 12) {
                    HeroMetric(title: "BLOCK PACE · MODEL ESTIMATE", value: model.difficulty.value.map { "~" + metric($0.timeAvg / 60000, digits: 1) } ?? "Unavailable", unit: "min", caption: "Observed epoch pace · probabilistic, not a countdown")
                    ObservationStatus(observation: model.difficulty, maxAge: 600) { Task { await model.refreshSlow() } }
                }.observatoryCard()
            }
            HStack(spacing: 36) {
                Text("PENDING  \(model.queue.value.map { $0.size.formatted() } ?? "Unavailable") tx")
                Text("QUEUED  \(metric(model.queue.value.map { $0.bytes / 1e6 })) vMB")
                Spacer()
                Button { model.select(.lightning) } label: { Text("ϟ PUBLIC LIGHTNING  \(metric(model.lightning.value?.capacityBTC, digits: 0)) BTC ↗") }
                    .buttonStyle(ObservatoryButtonStyle())
            }.font(.system(size: 24)).foregroundStyle(ObservatoryStyle.secondary)
            HStack {
                ObservationStatus(observation: model.queue) { Task { await model.refresh(slow: false) } }
                ObservationStatus(observation: model.lightning, maxAge: 36 * 3600) { Task { await model.refreshLightning() } }
            }
        }
    }
    private var priceChange: String {
        guard model.price.error == nil, model.priceHistory.error == nil,
              let quote = model.price.value, let history = model.priceHistory.value,
              let change = TelemetryMath.priceChange(current: quote, history: history.prices, now: Date()) else { return "24h comparison unavailable" }
        return String(format: "%+.2f%% · approximately 24h", change.percent) + "\nFrom " + change.date.formatted(date: .abbreviated, time: .shortened)
    }
    private func emptyWall(_ label: String) -> some View {
        Text(label).font(.system(size: 26)).foregroundStyle(ObservatoryStyle.secondary).frame(maxWidth: .infinity).frame(height: 190).observatoryCard()
    }
    private func blockTile(_ block: ChainBlock) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(block.extras?.pool?.name ?? "Pool unavailable").font(.system(size: 21)).lineLimit(1)
            Text(block.height.formatted(.number.grouping(.never))).font(.system(size: 40, weight: .semibold)).monospacedDigit()
            Text("\(metric(block.extras?.medianFee, digits: 2)) sat/vB").font(.system(size: 21))
            Text("Median · \(block.tx_count.formatted()) tx").font(.system(size: 21))
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18).frame(height: 190)
            .background(LinearGradient(colors: [ObservatoryStyle.orange.opacity(0.3), ObservatoryStyle.card], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ObservatoryStyle.orange.opacity(0.7)))
            .background(GeometryReader { proxy in Color.clear.preference(key: BlockFramePreference.self, value: [block.id: proxy.frame(in: .named("observatory"))]) })
    }
}
