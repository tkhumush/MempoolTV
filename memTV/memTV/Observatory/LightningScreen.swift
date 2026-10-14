import SwiftUI
import Charts

struct DatedValue: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}
struct ObservationChart: View {
    let points: [DatedValue]
    var tint = ObservatoryStyle.teal
    var gap: TimeInterval = 36 * 3600
    var body: some View {
        let ordered = points.sorted { $0.date < $1.date }
        let segments = segmented(ordered)
        Chart {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                ForEach(segment) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Value", point.value), series: .value("Observation segment", index))
                        .interpolationMethod(.linear).foregroundStyle(tint).lineStyle(StrokeStyle(lineWidth: 3))
                    PointMark(x: .value("Date", point.date), y: .value("Value", point.value)).foregroundStyle(tint).symbolSize(8)
                }
            }
        }.chartXAxis(.hidden).chartYAxis(.hidden).chartYScale(domain: .automatic(includesZero: false))
            .accessibilityLabel("Dated observations connected by straight lines; missing intervals remain gaps")
    }
    private func segmented(_ points: [DatedValue]) -> [[DatedValue]] {
        var result: [[DatedValue]] = []
        for point in points {
            if let previous = result.last?.last, point.date.timeIntervalSince(previous.date) <= gap { result[result.count - 1].append(point) }
            else { result.append([point]) }
        }
        return result
    }
}
struct LightningScreen: View {
    @ObservedObject var model: ObservatoryModel
    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            ScreenHeading(eyebrow: "A DIFFERENT KIND OF ENERGY", title: "Small payments. Extraordinary reach.", note: "ϟ LIGHTNING NETWORK\nPublicly observed topology")
            HStack(alignment: .top, spacing: 28) {
                growthCard("PUBLIC CAPACITY", unit: "BTC", caption: "Bitcoin in public channels", value: { $0.capacityBTC }, digits: 0)
                growthCard("PUBLIC CHANNELS", caption: "Connections between nodes", value: { Double($0.channel_count) }, digits: 0)
                growthCard("PUBLIC NODES", caption: "Peers in the public network", value: { Double($0.node_count) }, digits: 0)
            }.padding(.top, 65)
            ObservationStatus(observation: model.lightning, maxAge: 36 * 3600) { Task { await model.refreshLightning() } }
            ObservationStatus(observation: model.lightningHistory, maxAge: 36 * 3600) { Task { await model.refreshLightning() } }
            HStack {
                Text("PUBLIC SNAPSHOT · \(model.lightning.value?.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unavailable")")
                Spacer()
                Text("Capacity is not payment volume or spendable liquidity.")
            }.font(.system(size: 22)).foregroundStyle(ObservatoryStyle.secondary).padding(.top, 30)
        }
    }
    private func growthCard(_ title: String, unit: String = "", caption: String, value: (LightningSnapshot) -> Double, digits: Int) -> some View {
        let latest = model.lightning.value
        let history = historyEndingAtLatest
        let points = history.compactMap { snapshot in snapshot.date.map { DatedValue(date: $0, value: value(snapshot)) } }
        return VStack(alignment: .leading, spacing: 26) {
            HeroMetric(title: title, value: metric(latest.map(value), digits: digits), unit: unit, caption: caption)
            Text(growth(latest: latest, history: history, value: value)).font(.system(size: 24)).foregroundStyle(ObservatoryStyle.teal).frame(height: 62, alignment: .leading)
            if points.count >= 2 {
                ObservationChart(points: points).frame(height: 160)
                HStack {
                    Text(points.first!.date.formatted(date: .abbreviated, time: .omitted))
                    Spacer(); Text(points.last!.date.formatted(date: .abbreviated, time: .omitted))
                }.font(.system(size: 20)).foregroundStyle(ObservatoryStyle.secondary)
            } else { Text("30-day trend unavailable").frame(height: 195).foregroundStyle(ObservatoryStyle.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading).observatoryCard()
    }
    private var historyEndingAtLatest: [LightningSnapshot] {
        guard let latest = model.lightning.value, let date = latest.date else { return [] }
        var history = (model.lightningHistory.value ?? []).filter {
            guard let sample = $0.date else { return false }
            return sample >= date.addingTimeInterval(-30 * 86400) && sample < date
        }
        history.append(latest)
        return history.sorted { $0.date! < $1.date! }
    }
    private func growth(latest: LightningSnapshot?, history: [LightningSnapshot], value: (LightningSnapshot) -> Double) -> String {
        guard model.lightning.error == nil, model.lightningHistory.error == nil,
              let latest, let first = history.first, let end = latest.date, let start = first.date,
              end.timeIntervalSince(start) >= 86400, value(first) > 0 else { return "Growth unavailable" }
        let delta = value(latest) - value(first)
        let percent = delta / value(first) * 100
        return String(format: "%+.2f%% · %+.0f\nOver %.0f days observed", percent, delta, end.timeIntervalSince(start) / 86400)
    }
}
