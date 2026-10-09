import SwiftUI

struct ContentView: View {
    @StateObject private var model = ObservatoryModel()
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduced
    @FocusState private var focused: String?
    @State private var restoreFocus: String?
    @State private var blockFrames: [String: CGRect] = [:]

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 1920, geometry.size.height / 1080)
            composition
                .frame(width: 1920, height: 1080)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(ObservatoryStyle.canvas)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .background(RemoteInputObserver { model.input() })
        .task { model.setActive(phase == .active); focused = model.screen.rawValue }
        .onChange(of: phase) { _, value in model.setActive(value == .active) }
        .onDisappear { model.setActive(false) }
        .onChange(of: model.celebration?.id) { old, new in
            if new != nil { restoreFocus = focused; focused = "skip" }
            else if old != nil { focused = restoredFocus }
        }
        .onChange(of: model.dossier?.id) { old, new in
            if new != nil { restoreFocus = focused }
            else if old != nil { focused = restoredFocus }
        }
        .sheet(item: $model.dossier) { block in BlockDossier(block: block, api: model.api) }
        .onExitCommand {
            model.input()
            if model.celebration != nil { model.dismissCelebration() }
            else if model.dossier != nil { model.dossier = nil }
            else { model.select(.overview); focused = ObservatoryScreen.overview.rawValue }
        }
        .task {
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
                model.tick(now: Date())
            }
        }
    }
    private var restoredFocus: String {
        guard let restoreFocus else { return model.screen.rawValue }
        let isNav = ObservatoryScreen.allCases.contains { $0.rawValue == restoreFocus }
        let isVisibleBlock = model.screen == .overview && (model.blocks.value?.prefix(3).contains { $0.id == restoreFocus } ?? false)
        return isNav || isVisibleBlock ? restoreFocus : model.screen.rawValue
    }
    private var composition: some View {
        ZStack {
            ObservatoryStyle.canvas
            RadialGradient(colors: [ObservatoryStyle.violet.opacity(0.07), .clear], center: .topTrailing, startRadius: 0, endRadius: 1300)
            VStack(spacing: 16) {
                header
                Group {
                    switch model.screen {
                    case .overview: OverviewScreen(model: model, focus: $focused)
                    case .fees: FeeMarketScreen(model: model)
                    case .mining: MiningScreen(model: model)
                    case .lightning: LightningScreen(model: model)
                    }
                }
                .id(model.screen)
                .transition(.opacity)
                .frame(maxHeight: .infinity, alignment: .top)
                footer
            }
            .padding(.horizontal, 88).padding(.vertical, 44)
            .allowsHitTesting(model.celebration == nil)
            .disabled(model.celebration != nil)
            .accessibilityHidden(model.celebration != nil)
            if let block = model.celebration {
                BlockCelebration(block: block, source: blockFrames[block.id], focus: $focused) {
                    model.dismissCelebration()
                } settling: {
                    model.select(.overview, user: false)
                }
                .id(block.id).zIndex(10)
            }
        }
        .coordinateSpace(name: "observatory")
        .onPreferenceChange(BlockFramePreference.self) { blockFrames = $0 }
        .foregroundStyle(ObservatoryStyle.text)
        .animation(reduced ? nil : .easeInOut(duration: 0.28), value: model.screen)
    }
    private var header: some View {
        HStack(spacing: 30) {
            Text("▥ mempoolTV").font(.system(size: 32, weight: .bold)).foregroundStyle(ObservatoryStyle.orange)
            Spacer(minLength: 10)
            ForEach(ObservatoryScreen.allCases) { screen in
                Button { model.select(screen) } label: {
                    Text(screen.rawValue).font(.system(size: 26, weight: .medium))
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) { Capsule().fill(screen == model.screen ? ObservatoryStyle.orange : .clear).frame(height: 3) }
                }.buttonStyle(ObservatoryButtonStyle()).focused($focused, equals: screen.rawValue)
            }
            Spacer(minLength: 10)
            VStack(alignment: .trailing, spacing: 5) {
                Text(model.price.value.map { "$" + metric($0.USD, digits: 0) } ?? "USD unavailable").font(.system(size: 28, weight: .semibold)).monospacedDigit()
                Text(model.price.error != nil ? "QUOTE STALE" : model.healthy ? "● LIVE" : "○ RECONNECTING").font(.system(size: 18)).foregroundStyle(model.healthy ? ObservatoryStyle.teal : ObservatoryStyle.stale)
            }
        }.frame(height: 66)
    }
    private var footer: some View {
        HStack {
            Text(model.connection).lineLimit(1).frame(maxWidth: 860, alignment: .leading)
            Button("Reconnect") { model.retryLive() }.buttonStyle(ObservatoryButtonStyle())
            Spacer()
            Button(model.ambientEnabled ? model.ambientPaused ? "Ambient · resumes after 60s idle" : "Ambient · on" : "Ambient · off") { model.toggleAmbient() }
                .buttonStyle(ObservatoryButtonStyle())
            Text("\((ObservatoryScreen.allCases.firstIndex(of: model.screen) ?? 0) + 1) / 4").monospacedDigit()
            if model.ambientEnabled { ProgressView(value: model.rotationProgress).frame(width: 90).tint(ObservatoryStyle.teal) }
        }.font(.system(size: 21)).foregroundStyle(ObservatoryStyle.secondary).frame(height: 48)
    }
}

struct BlockFramePreference: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue(), uniquingKeysWith: { _, new in new }) }
}
