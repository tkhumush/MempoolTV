import SwiftUI

struct MiningScreen: View {
    @ObservedObject var model: ObservatoryModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScreenHeading(eyebrow: "PROOF OF WORK, IN MOTION", title: "The heartbeat of Bitcoin.", note: "One block at a time.", tint: ObservatoryStyle.orange)
            HStack(alignment: .top, spacing: 60) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack { Text("WHO’S BUILDING THE CHAIN"); Spacer(); Text("SHARE OF BLOCKS") }.font(.system(size: 23)).foregroundStyle(ObservatoryStyle.secondary)
                    poolBars
                    Text("Pool shares · rolling 1-week window").font(.system(size: 22)).foregroundStyle(ObservatoryStyle.secondary)
                    ObservationStatus(observation: model.pools, maxAge: 600) { Task { await model.refreshSlow() } }
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NETWORK HASHRATE · PROVIDER ESTIMATE").font(.system(size: 22)).foregroundStyle(ObservatoryStyle.secondary)
                            Text(metric(model.hashrate.value.map { $0.currentHashrate / 1e18 }, digits: 0) + " EH/s").font(.system(size: 64, weight: .semibold)).monospacedDigit()
                        }
                        Spacer(); Text("30-day history").font(.system(size: 23)).foregroundStyle(ObservatoryStyle.teal)
                    }
                    if history.count >= 2 {
                        ObservationChart(points: history, tint: ObservatoryStyle.orange).frame(height: 130)
                        HStack {
                            Text(history.first!.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer(); Text(history.last!.date.formatted(date: .abbreviated, time: .omitted))
                        }.font(.system(size: 20)).foregroundStyle(ObservatoryStyle.secondary)
                    } else { Text("Hashrate history unavailable").frame(height: 130) }
                    ObservationStatus(observation: model.hashrate, maxAge: 600) { Task { await model.refreshSlow() } }
                }.frame(maxWidth: .infinity)
                epoch.frame(width: 570).observatoryCard()
            }
        }
    }
    private var history: [DatedValue] {
        guard let points = model.hashrate.value?.hashrates else { return [] }
        let end = Date().timeIntervalSince1970
        return points.filter { $0.timestamp <= end && $0.timestamp >= end - 30 * 86400 }
            .sorted { $0.timestamp < $1.timestamp }
            .map { DatedValue(date: Date(timeIntervalSince1970: $0.timestamp), value: $0.avgHashrate / 1e18) }
    }
    private struct PoolRow: Identifiable {
        let id: String; let name: String; let count: Int; let tenths: Int
    }
    private var rows: [PoolRow] {
        guard let window = model.pools.value, window.blockCount > 0 else { return [] }
        let sorted = window.pools.sorted { $0.blockCount == $1.blockCount ? $0.poolId < $1.poolId : $0.blockCount > $1.blockCount }
        let counts = sorted.prefix(5).map(\.blockCount)
        let other = window.blockCount - counts.reduce(0, +)
        guard other >= 0 else { return [] }
        let shares = TelemetryMath.shares(counts + [other])
        guard shares.count == counts.count + 1 else { return [] }
        var values = sorted.prefix(5).enumerated().map { index, pool in
            PoolRow(id: String(pool.poolId), name: pool.name, count: pool.blockCount, tenths: shares[index])
        }
        values.append(PoolRow(id: "other", name: "Other pools / unattributed", count: other, tenths: shares.last!))
        return values
    }
    @ViewBuilder private var poolBars: some View {
        if rows.isEmpty { Text("Pool shares unavailable").font(.system(size: 28)).frame(height: 280) }
        else {
            VStack(spacing: 15) {
                ForEach(rows) { row in
                    HStack(spacing: 16) {
                        Text(row.name).font(.system(size: 23)).lineLimit(1).frame(width: 290, alignment: .leading)
                        GeometryReader { proxy in
                            Capsule().fill(ObservatoryStyle.orange.opacity(0.08))
                            Capsule().fill(LinearGradient(colors: [ObservatoryStyle.orange.opacity(0.5), ObservatoryStyle.orange], startPoint: .leading, endPoint: .trailing))
                                .frame(width: proxy.size.width * Double(row.count) / Double(max(1, rows.map(\.count).max() ?? 1)))
                        }.frame(height: 16)
                        Text(String(format: "%.1f%%", Double(row.tenths) / 10)).font(.system(size: 25, weight: .semibold)).monospacedDigit().frame(width: 92, alignment: .trailing)
                    }.frame(height: 30)
                }
            }.animation(reduced ? nil : .easeInOut(duration: 0.65), value: rows.map { "\($0.id):\($0.count)" })
        }
    }
    private var epoch: some View {
        let clock = model.blocks.value?.first.map { TelemetryMath.epoch(height: $0.height) }
        let remaining = clock?.remaining ?? model.difficulty.value?.remainingBlocks
        let progress = clock?.progress ?? model.difficulty.value.map { min(1, max(0, $0.progressPercent / 100)) }
        return VStack(spacing: 22) {
            Text("THE EPOCH CLOCK").font(.system(size: 23, weight: .medium)).tracking(3).foregroundStyle(ObservatoryStyle.orange)
            ZStack {
                Circle().stroke(ObservatoryStyle.orange.opacity(0.1), lineWidth: 15)
                if let progress {
                    Circle().trim(from: 0, to: progress).stroke(AngularGradient(colors: [ObservatoryStyle.orange.opacity(0.5), ObservatoryStyle.orange], center: .center), style: StrokeStyle(lineWidth: 15, lineCap: .round)).rotationEffect(.degrees(-90))
                        .animation(reduced ? nil : .linear(duration: 2), value: progress)
                }
                Circle().stroke(ObservatoryStyle.orange.opacity(0.15), style: StrokeStyle(lineWidth: 3, dash: [2, 15])).padding(-17)
                VStack(spacing: 12) {
                    Text("UNTIL RETARGET").font(.system(size: 22)).foregroundStyle(ObservatoryStyle.secondary)
                    Text(remaining.map { $0.formatted() } ?? "Unavailable").font(.system(size: remaining == nil ? 36 : 88, weight: .semibold)).monospacedDigit().contentTransition(.numericText())
                    Text("blocks remaining").font(.system(size: 26))
                    Text(metric(progress.map { $0 * 100 }, digits: 1) + "% complete").font(.system(size: 23)).foregroundStyle(ObservatoryStyle.secondary)
                }
            }.frame(width: 370, height: 370).padding(20)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ESTIMATED RETARGET").font(.system(size: 19))
                    Text(model.difficulty.value.map { Date(timeIntervalSince1970: $0.estimatedRetargetDate / 1000).formatted(date: .abbreviated, time: .shortened) } ?? "Unavailable").font(.system(size: 25, weight: .medium))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 12) {
                    Text("PROJECTED CHANGE").font(.system(size: 19))
                    Text(model.difficulty.value.map { String(format: "%+.2f%%", $0.difficultyChange) } ?? "Unavailable").font(.system(size: 30, weight: .semibold)).foregroundStyle(ObservatoryStyle.teal)
                }
            }
            Text("Estimated from observed block pace.\nThe network sets the final difficulty.").font(.system(size: 23)).foregroundStyle(ObservatoryStyle.secondary)
            ObservationStatus(observation: model.difficulty, maxAge: 600) { Task { await model.refreshSlow() } }
            if model.blocks.error != nil { Text("Chain clock stale · reconnect to reconcile").font(.system(size: 20)).foregroundStyle(ObservatoryStyle.stale) }
        }
    }
}
