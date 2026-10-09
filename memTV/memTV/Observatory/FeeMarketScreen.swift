import SwiftUI

struct FeeMarketScreen: View {
    @ObservedObject var model: ObservatoryModel
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ScreenHeading(eyebrow: "THE FEE MARKET", title: "A place in the next block.", note: "\(metric(model.incoming.value, digits: 0)) vB/s incoming", tint: ObservatoryStyle.violet)
            ObservationStatus(observation: model.incoming) { model.retryLive() }
            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("NEXT BLOCK  ·  PROJECTED ESTIMATE")
                        Spacer()
                        Text(metric(model.template.value.map { $0.reduce(0) { $0 + $1.vsize } / 1e6 }, digits: 3, suffix: " vMB"))
                    }.font(.system(size: 23)).foregroundStyle(ObservatoryStyle.secondary)
                    if let transactions = model.template.value {
                        if transactions.isEmpty {
                            Text("Measured template is empty").frame(maxWidth: .infinity).frame(height: 330).observatoryCard()
                        } else {
                            TransactionMosaic(transactions: transactions).frame(height: 330)
                                .opacity(model.template.error == nil ? 1 : 0.4)
                        }
                    } else {
                        Text("Live transaction template unavailable").font(.system(size: 30)).frame(maxWidth: .infinity).frame(height: 330).observatoryCard()
                    }
                    HStack(spacing: 14) {
                        Text("AREA = VSIZE")
                        Spacer()
                        ForEach(0..<5) { band in
                            Circle().fill(ObservatoryStyle.bands[band]).frame(width: 12, height: 12)
                            Text(ObservatoryStyle.bandLabels[band])
                        }
                        Text("sat/vB")
                    }.font(.system(size: 21)).foregroundStyle(ObservatoryStyle.secondary)
                    Text("Color = effective/package fee rate · small transactions grouped within their band")
                        .font(.system(size: 21)).foregroundStyle(ObservatoryStyle.secondary)
                    ObservationStatus(observation: model.template) { model.retryTemplate() }
                }.frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 25) {
                    HeroMetric(title: "GET INTO THE NEXT BLOCK", value: metric(model.fees.value?.fastestFee, digits: 2), caption: "sat/vB recommended")
                    Divider()
                    feeRow("~30 min estimate", model.fees.value?.halfHourFee)
                    feeRow("~1 hour estimate", model.fees.value?.hourFee)
                    feeRow("Economy", model.fees.value?.economyFee)
                    Text("Recommendations are estimates. Templates change as transactions arrive.").font(.system(size: 23)).foregroundStyle(ObservatoryStyle.secondary)
                    ObservationStatus(observation: model.fees) { Task { await model.refresh(slow: false) } }
                }.frame(width: 380).observatoryCard()
            }
            HStack {
                Text("THE WAITING ROOM").font(.system(size: 25, weight: .semibold)).tracking(2)
                Text("Queued vsize · current snapshot").font(.system(size: 22)).foregroundStyle(ObservatoryStyle.secondary)
                Spacer()
                Text(metric(model.backlog.value?.bands.map { $0.reduce(0, +) / 1e6 }, digits: 2, suffix: " vMB"))
            }
            if let bands = model.backlog.value?.bands {
                BacklogStrip(bands: bands).frame(height: 46)
                HStack {
                    ForEach(0..<5) { index in
                        Text("\(ObservatoryStyle.bandLabels[index]) sat/vB · \(metric(bands[index] / 1e6, digits: 2)) vMB")
                            .foregroundStyle(ObservatoryStyle.bands[index]).frame(maxWidth: .infinity)
                    }
                }.font(.system(size: 20))
            } else { Text("Fee-band backlog unavailable").font(.system(size: 26)).foregroundStyle(ObservatoryStyle.secondary) }
            ObservationStatus(observation: model.backlog, maxAge: 300) { Task { await model.refreshBacklog() } }
        }
    }
    private func feeRow(_ label: String, _ value: Double?) -> some View {
        HStack { Text(label); Spacer(); Text(metric(value, digits: 2)).monospacedDigit() }.font(.system(size: 26))
    }
}
struct TransactionMosaic: View {
    let transactions: [TemplateTransaction]
    var body: some View {
        Canvas { context, size in
            let cells = MosaicLayout.make(transactions, width: size.width, height: size.height)
            for cell in cells {
                let path = Path(cell.rect)
                context.fill(path, with: .color(ObservatoryStyle.bands[cell.band]))
                context.stroke(path, with: .color(ObservatoryStyle.canvas.opacity(0.75)), lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel("Projected transaction mosaic. Area represents supplied virtual size. Color represents effective fee rate. \(transactions.count) transactions.")
    }
}
struct BacklogStrip: View {
    let bands: [Double]
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body: some View {
        GeometryReader { proxy in
            let total = bands.reduce(0, +)
            if total > 0 {
                HStack(spacing: 0) {
                    ForEach((0..<5).reversed(), id: \.self) { index in
                        Rectangle().fill(ObservatoryStyle.bands[index]).frame(width: proxy.size.width * bands[index] / total)
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 10)).animation(reduced ? nil : .easeInOut(duration: 1.5), value: bands)
            } else { Text("Measured queue is empty").font(.system(size: 24)).foregroundStyle(ObservatoryStyle.secondary) }
        }
    }
}
