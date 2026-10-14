import SwiftUI
import UIKit

/// Observes remote presses at the window without consuming them or changing focus behavior.
struct RemoteInputObserver: UIViewRepresentable {
    var onInput: () -> Void
    func makeUIView(context: Context) -> ObserverView { ObserverView(onInput: onInput) }
    func updateUIView(_ view: ObserverView, context: Context) { view.onInput = onInput }
    static func dismantleUIView(_ view: ObserverView, coordinator: ()) { view.detach() }
    final class ObserverView: UIView {
        var onInput: () -> Void
        private weak var attachedWindow: UIWindow?
        private var recognizer: PressObserver?
        init(onInput: @escaping () -> Void) { self.onInput = onInput; super.init(frame: .zero); isUserInteractionEnabled = false }
        required init?(coder: NSCoder) { nil }
        override func didMoveToWindow() {
            super.didMoveToWindow(); detach()
            guard let window else { return }
            let observer = PressObserver { [weak self] in self?.onInput() }
            window.addGestureRecognizer(observer); attachedWindow = window; recognizer = observer
        }
        func detach() {
            if let recognizer { attachedWindow?.removeGestureRecognizer(recognizer) }
            recognizer = nil; attachedWindow = nil
        }
    }
    final class PressObserver: UIGestureRecognizer {
        let onInput: () -> Void
        init(onInput: @escaping () -> Void) {
            self.onInput = onInput; super.init(target: nil, action: nil)
            cancelsTouchesInView = false; delaysTouchesBegan = false; delaysTouchesEnded = false
        }
        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent) { onInput(); state = .failed }
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) { onInput(); state = .failed }
    }
}
