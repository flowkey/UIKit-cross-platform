import UIKit

// XCUIApplication/XCUIElement façade over the live UIView tree, API-shaped like XCUITest so the same
// test reads identically. Runs on the test thread; every UIKit access hops to the main actor.

public struct TestFailure: Error, CustomStringConvertible {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

public struct XCUIApplication {
    public init() {}
    public var buttons: XCUIElementQuery { XCUIElementQuery() }
    public var otherElements: XCUIElementQuery { XCUIElementQuery() }
    public var navigationBars: XCUIElementQuery { XCUIElementQuery() }
}

public struct XCUIElementQuery {
    public subscript(_ identifier: String) -> XCUIElement { XCUIElement(identifier: identifier) }
}

public struct XCUIElement {
    let identifier: String

    /// Resolve the live view by `accessibilityIdentifier`, falling back to a label/title match.
    @MainActor private func resolvedView() -> UIView? {
        guard let window = UIApplication.shared.keyWindow else { return nil }
        return window.firstDescendant(matchingIdentifier: identifier)
            ?? window.firstDescendant(matchingLabel: identifier)
    }

    public var exists: Bool { onMain { resolvedView() != nil } }

    public var label: String? { onMain { resolvedView()?.firstLabelText } }

    /// The element's frame in window coordinates (main-actor; call within `onMain`).
    @MainActor func windowFrame() -> CGRect? {
        guard let view = resolvedView(), let window = UIApplication.shared.keyWindow else { return nil }
        let origin = view.convert(CGPoint.zero, to: window)
        return CGRect(x: origin.x, y: origin.y, width: view.bounds.width, height: view.bounds.height)
    }

    public var frame: CGRect { onMain { windowFrame() ?? .zero } }

    /// A coordinate within this element, for drags (XCUITest-style).
    public func coordinate(withNormalizedOffset offset: CGVector) -> XCUICoordinate {
        XCUICoordinate(element: self, normalizedOffset: offset)
    }

    /// Poll (on the test thread) until the element exists or the timeout elapses.
    @discardableResult
    public func waitForExistence(timeout: Double = 10) -> Bool {
        var elapsed = 0.0
        while elapsed < timeout {
            if exists { return true }
            testSleep(0.016)
            elapsed += 0.016
        }
        return exists
    }

    /// Tap a *hittable* point of the element (one that hit-tests to it), then let the app render a few
    /// frames so a following assertion sees the settled state.
    @discardableResult
    public func tap() -> XCUIElement {
        onMain {
            guard let view = resolvedView(),
                  let window = UIApplication.shared.keyWindow,
                  let point = window.hittablePoint(for: view)
            else { return }
            UIApplication.shared.simulateTap(at: point)
        }
        testSleep(0.6) // let the UI react + any present/dismiss animation settle
        return self
    }
}

/// XCUITest-style CGVector (the polyfill has no CGVector; on iOS this name resolves to CoreGraphics').
public struct CGVector {
    public var dx: CGFloat
    public var dy: CGFloat
    public init(dx: CGFloat, dy: CGFloat) { self.dx = dx; self.dy = dy }
    public static let zero = CGVector(dx: 0, dy: 0)
}

public struct XCUICoordinate {
    let element: XCUIElement
    let normalizedOffset: CGVector

    /// Press at this coordinate and drag to `other`, paced one move per frame so the app renders the
    /// finger travelling pixel-by-pixel (not a single jump), like a real drag.
    public func press(forDuration duration: Double, thenDragTo other: XCUICoordinate) {
        guard let endpoints = onMain({ () -> (from: CGPoint, to: CGPoint)? in
            guard let a = element.windowFrame(), let b = other.element.windowFrame() else { return nil }
            return (from: CGPoint(x: a.minX + a.width * normalizedOffset.dx,
                                  y: a.minY + a.height * normalizedOffset.dy),
                    to: CGPoint(x: b.minX + b.width * other.normalizedOffset.dx,
                                y: b.minY + b.height * other.normalizedOffset.dy))
        }) else { return }

        let from = endpoints.from, to = endpoints.to
        let steps = 30
        let event = onMain { UIApplication.shared.beginTouch(at: from) }
        for step in 1 ... steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let point = CGPoint(x: from.x + (to.x - from.x) * progress,
                                y: from.y + (to.y - from.y) * progress)
            onMain { UIApplication.shared.moveTouch(event, to: point) }
            testSleep(0.016) // one frame per move → smooth, rendered drag
        }
        onMain { UIApplication.shared.endTouch(event) }
        testSleep(0.3)
    }
}
