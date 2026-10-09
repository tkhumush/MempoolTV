import SwiftUI

enum ObservatoryStyle {
    static let canvas = Color(hex: 0x090D14)
    static let card = Color(hex: 0x141C28)
    static let text = Color(hex: 0xF3F8FA)
    static let secondary = Color(hex: 0xB4C0D0)
    static let orange = Color(hex: 0xFFAD47)
    static let violet = Color(hex: 0xA696FF)
    static let teal = Color(hex: 0x6CE2CA)
    static let stale = Color(hex: 0xEDC77F)
    static let unavailable = Color(hex: 0xC37F88)
    static let bands = [0x6867B5, 0x7662CF, 0xB078B5, 0xDC966F, 0xFFBD65].map { Color(hex: $0) }
    static let bandLabels = ["<2", "2–5", "5–10", "10–20", "≥20"]
}

extension Color {
    init(hex: Int) {
        self.init(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }
}
func metric(_ value: Double?, digits: Int = 1, suffix: String = "") -> String {
    guard let value, value.isFinite, value >= 0 else { return "Unavailable" }
    return value.formatted(.number.precision(.fractionLength(digits))) + suffix
}

struct ObservatoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { FocusSurface(configuration: configuration) }
    private struct FocusSurface: View {
        let configuration: Configuration
        @Environment(\.isFocused) private var focused
        @Environment(\.accessibilityReduceMotion) private var reduced
        var body: some View {
            configuration.label
                .padding(8)
                .background(focused ? ObservatoryStyle.teal.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(focused ? ObservatoryStyle.teal : .clear, lineWidth: 3))
                .shadow(color: focused ? ObservatoryStyle.teal.opacity(0.2) : .clear, radius: 14)
                .scaleEffect(reduced ? 1 : configuration.isPressed ? 0.99 : focused ? 1.025 : 1)
                .animation(reduced ? nil : .spring(response: 0.2, dampingFraction: 0.8), value: focused)
        }
    }
}
struct ScreenHeading: View {
    let eyebrow: String
    let title: String
    var note = ""
    var tint = ObservatoryStyle.teal
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text(eyebrow).font(.system(size: 22, weight: .semibold)).tracking(3).foregroundStyle(tint)
                Text(title).font(.system(size: 54, weight: .semibold)).tracking(-2)
            }
            Spacer()
            Text(note).font(.system(size: 24)).foregroundStyle(ObservatoryStyle.secondary).multilineTextAlignment(.trailing)
        }.padding(.vertical, 12)
    }
}
struct ObservationStatus<Value>: View {
    let observation: Observation<Value>
    var maxAge: TimeInterval = 120
    let retry: () -> Void
    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            HStack(spacing: 12) {
                Text(observation.status(now: context.date, maxAge: maxAge))
                    .foregroundStyle(observation.error == nil ? ObservatoryStyle.secondary : ObservatoryStyle.stale)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Button(action: retry) { Image(systemName: "arrow.clockwise") }
                    .accessibilityLabel("Retry data")
                    .buttonStyle(ObservatoryButtonStyle())
            }.font(.system(size: 19))
        }
    }
}
struct HeroMetric: View {
    let title: String
    let value: String
    var unit = ""
    var caption = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 22, weight: .medium)).tracking(2).foregroundStyle(ObservatoryStyle.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(value).font(.system(size: value == "Unavailable" ? 36 : 72, weight: .semibold)).monospacedDigit().contentTransition(.numericText())
                    .minimumScaleFactor(0.65).lineLimit(1)
                Text(unit).font(.system(size: 25)).foregroundStyle(ObservatoryStyle.secondary)
            }
            Text(caption).font(.system(size: 23)).foregroundStyle(ObservatoryStyle.secondary).lineLimit(2)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
extension View {
    func observatoryCard() -> some View {
        self.padding(22).background(ObservatoryStyle.card, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.08), lineWidth: 1))
    }
}
