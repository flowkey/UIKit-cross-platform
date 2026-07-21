@_spi(UITest) import UIKit

// UI-test primitives built on UIKit's public API (plus the @_spi(UITest) UITouch/UIEvent seam for
// synthesizing touches). These use the polyfill's *real* hitTest / touch dispatch, so they behave
// exactly like a finger would.

extension UIView {
    /// First *visible* descendant (including `self`) matching `predicate`. Hidden/transparent
    /// subtrees are skipped (searched top z-order first), mirroring `hitTest` and XCUITest `.exists`.
    func firstDescendant(where predicate: (UIView) -> Bool) -> UIView? {
        guard !isHidden, alpha > 0.01 else { return nil }
        if predicate(self) { return self }
        for subview in subviews.reversed() {
            if let match = subview.firstDescendant(where: predicate) { return match }
        }
        return nil
    }

    /// First visible descendant whose `accessibilityIdentifier` matches.
    func firstDescendant(matchingIdentifier identifier: String) -> UIView? {
        firstDescendant { $0.accessibilityIdentifier == identifier }
    }

    /// First visible descendant whose own label/title text matches — lets tests find buttons and
    /// nav bars by their visible title (e.g. "Done"), like XCUITest matching by label.
    func firstDescendant(matchingLabel text: String) -> UIView? {
        firstDescendant { ($0 as? UILabel)?.text == text }
    }

    /// First descendant `UILabel`'s text, for asserting on rendered copy.
    var firstLabelText: String? {
        if let label = self as? UILabel { return label.text }
        for subview in subviews {
            if let text = subview.firstLabelText { return text }
        }
        return nil
    }

    func isSelfOrDescendant(of ancestor: UIView) -> Bool {
        var view: UIView? = self
        while let current = view {
            if current === ancestor { return true }
            view = current.superview
        }
        return false
    }

    /// A point (in the receiver's coordinate space) that actually hit-tests to `target` (or a
    /// descendant of it) — i.e. a point where tapping reaches `target`, skipping any view that
    /// covers its centre. Tries the centre first, then a coarse grid. Nil if fully covered.
    func hittablePoint(for target: UIView) -> CGPoint? {
        let bounds = target.bounds
        let fractions: [CGFloat] = [0.5, 0.25, 0.75, 0.15, 0.85]
        for verticalFraction in fractions {
            for horizontalFraction in fractions {
                let pointInTarget = CGPoint(x: bounds.minX + bounds.width * horizontalFraction,
                                            y: bounds.minY + bounds.height * verticalFraction)
                let pointInSelf = target.convert(pointInTarget, to: self)
                // Accept when the hit view is the target, a descendant of it, OR an ancestor of it
                // (tapping a non-interactive label's spot reaches its containing button).
                if let hit = hitTest(pointInSelf, with: nil),
                   hit.isSelfOrDescendant(of: target) || target.isSelfOrDescendant(of: hit) {
                    return pointInSelf
                }
            }
        }
        return nil
    }
}

extension UIApplication {
    /// Synthesize a full tap (began → ended) at a point in the key window's coordinate space,
    /// dispatched through the real `sendEvent` → `hitTest` path so gesture recognizers fire exactly
    /// as they would for a finger.
    func simulateTap(at pointInWindow: CGPoint) {
        let touch = UITouch(touchId: 0, at: pointInWindow, timestamp: 0)
        let event = UIEvent(touch: touch)

        touch.phase = .began
        sendEvent(event)

        touch.phase = .ended
        sendEvent(event)
    }

    // Per-phase touch primitives so a drag can be paced one move per frame (dispatched from the test
    // thread, one main hop each), producing a smooth pixel-by-pixel drag instead of a single jump.
    // One `UIEvent` is reused across all phases (it retains the touch), mirroring the real SDL path.

    /// Begin a touch at a window point; returns the event to feed to `moveTouch`/`endTouch`.
    func beginTouch(at point: CGPoint) -> UIEvent {
        let touch = UITouch(touchId: 0, at: point, timestamp: 0)
        let event = UIEvent(touch: touch)
        touch.phase = .began
        sendEvent(event)
        return event
    }

    func moveTouch(_ event: UIEvent, to point: CGPoint) {
        guard let touch = event.allTouches?.first else { return }
        touch.updateAbsoluteLocation(point)
        touch.phase = .moved
        sendEvent(event)
    }

    func endTouch(_ event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        touch.phase = .ended
        sendEvent(event)
    }
}
