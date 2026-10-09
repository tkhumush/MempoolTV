import SwiftUI

struct BlockCelebration: View {
    let block: ChainBlock
    let source: CGRect?
    let focus: FocusState<String?>.Binding
    let dismiss: () -> Void
    let settling: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var stage = 0
    private var expanded: Bool { reduced || (stage >= 1 && stage < 6) }
    var body: some View {
        GeometryReader { geometry in
            let target = source ?? CGRect(x: geometry.size.width / 2 - 120, y: 320, width: 240, height: 190)
            ZStack {
                Color.black.opacity(stage == 6 && !reduced ? 0 : 0.88).ignoresSafeArea()
                VStack(spacing: 18) {
                    Text("A NEW CHAPTER, IMMUTABLY WRITTEN").font(.system(size: 20, weight: .medium)).tracking(2).foregroundStyle(ObservatoryStyle.orange)
                    Text("BLOCK").font(.system(size: 28, weight: .semibold)).tracking(5)
                    Text(block.height.formatted(.number.grouping(.never)))
                        .font(.system(size: 112, weight: .semibold)).monospacedDigit().minimumScaleFactor(0.7)
                    metadata("MINED BY", block.extras?.pool?.name ?? "Unavailable", stage: 2)
                    metadata("TRANSACTIONS", block.tx_count.formatted(), stage: 3)
                    metadata("TOTAL FEES", metric(block.extras?.totalFees.map { $0 / 1e8 }, digits: 4, suffix: " BTC"), stage: 4)
                    Text("✓ Secured by proof of work").font(.system(size: 23)).foregroundStyle(ObservatoryStyle.orange).opacity(reduced || stage >= 5 ? 1 : 0)
                }
                .padding(36).frame(width: 650, height: 630)
                .background(LinearGradient(colors: [Color(hex: 0x493323), ObservatoryStyle.card], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(ObservatoryStyle.orange, lineWidth: 2))
                .shadow(color: ObservatoryStyle.orange.opacity(0.25), radius: 65)
                .scaleEffect(expanded ? 1 : target.width / 650)
                .position(expanded ? CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2) : CGPoint(x: target.midX, y: target.midY))
                .opacity(stage == 0 && !reduced ? 0 : 1)
                VStack { Spacer(); Button("Back · Skip", action: dismiss).buttonStyle(ObservatoryButtonStyle()).focused(focus, equals: "skip").padding(.bottom, 55) }
            }
        }
        .onExitCommand(perform: dismiss)
        .task {
            if reduced {
                do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
                dismiss(); return
            }
            do {
                try await wait(0.4)
                withAnimation(.easeInOut(duration: 0.8)) { stage = 1 }
                try await wait(0.85); withAnimation(.easeOut(duration: 0.3)) { stage = 2 }
                try await wait(0.85); withAnimation(.easeOut(duration: 0.3)) { stage = 3 }
                try await wait(0.85); withAnimation(.easeOut(duration: 0.3)) { stage = 4 }
                try await wait(0.6); withAnimation(.easeOut(duration: 0.3)) { stage = 5 }
                try await wait(0.45); settling()
                // Give Overview a layout pass to resolve the actual destination tile.
                try await wait(0.05); withAnimation(.spring(response: 0.85, dampingFraction: 0.9)) { stage = 6 }
                try await wait(0.95); dismiss()
            } catch { return }
        }
        .accessibilityAddTraits(.isModal)
    }
    private func wait(_ seconds: Double) async throws { try await Task.sleep(nanoseconds: UInt64(seconds * 1e9)) }
    private func metadata(_ label: String, _ value: String, stage threshold: Int) -> some View {
        HStack {
            Text(label).font(.system(size: 21)).foregroundStyle(ObservatoryStyle.secondary)
            Spacer(); Text(value).font(.system(size: 28, weight: .semibold)).monospacedDigit()
        }.padding(.vertical, 12).overlay(alignment: .top) { Rectangle().fill(ObservatoryStyle.orange.opacity(0.2)).frame(height: 1) }
            .opacity(reduced || stage >= threshold ? 1 : 0)
    }
}
