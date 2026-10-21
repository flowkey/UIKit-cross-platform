import Dispatch

open class UILongPressGestureRecognizer: UIGestureRecognizer {
    public var minimumPressDuration: Double = 0.5
    public var allowableMovement: CGFloat = 10
    public var numberOfTouchesRequired = 1

    private var startLocation: CGPoint?
    private var pressID = 0

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard state == .possible else { return }
        if numberOfTouches > numberOfTouchesRequired { state = .failed; return }
        guard numberOfTouches == numberOfTouchesRequired else { return }

        startLocation = location(in: nil)
        pressID += 1
        let id = pressID
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumPressDuration) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.pressID == id, self.state == .possible, !self.activeTouches.isEmpty else { return }
                self.state = .began
            }
        }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        switch state {
        case .possible:
            guard let startLocation else { return }
            if (location(in: nil) - startLocation).magnitude > allowableMovement { state = .failed }
        case .began, .changed:
            state = .changed
        case .ended, .cancelled, .failed:
            break
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard activeTouches.isEmpty else { return }
        state = state == .possible ? .failed : .ended
    }

    open override func reset() {
        super.reset()
        startLocation = nil
        pressID += 1
    }
}
