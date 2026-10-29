@MainActor
public class UITouch {
    public init() {
        absoluteLocation = .zero
        previousAbsoluteLocation = .zero
        timestamp = 0
        touchId = 0
    }

    internal init(touchId: Int, at point: CGPoint, timestamp: Double) {
        absoluteLocation = point
        previousAbsoluteLocation = point
        self.touchId = touchId
        self.timestamp = timestamp
    }

    internal let touchId: Int

    public weak var view: UIView?
    public weak var window: UIWindow?

    public var phase: UITouchPhase = .began
    public var timestamp: Double

    private var absoluteLocation: CGPoint
    private var previousAbsoluteLocation: CGPoint

    func updateAbsoluteLocation(_ newLocation: CGPoint) {
        previousAbsoluteLocation = absoluteLocation
        absoluteLocation = newLocation
    }

    public func location(in view: UIView?) -> CGPoint {
        return window?.convert(absoluteLocation, to: view) ?? absoluteLocation
    }

    public func previousLocation(in view: UIView?) -> CGPoint {
        return window?.convert(previousAbsoluteLocation, to: view) ?? previousAbsoluteLocation
    }

    public internal(set) var gestureRecognizers: [UIGestureRecognizer] = []

    internal weak var event: UIEvent?

    /// Set once a recognizer cancelled this touch for its view: the view gets `touchesCancelled` and nothing after.
    internal private(set) var hasBeenCancelledByAGestureRecognizer = false
    private enum ViewDelivery { case pending, began, discarded, finished }
    private var viewDelivery = ViewDelivery.pending
    private var delayedViewPhases: [UITouchPhase] = []

    /// Hands the touch's current phase to its view, unless a recognizer cancelled it or delays it.
    func maybeDeliverToView() {
        if hasBeenCancelledByAGestureRecognizer { return }
        if !delayedViewPhases.isEmpty || isDelayedByAGestureRecognizer {
            delayedViewPhases.append(phase)
            return
        }
        deliverToView(phase)
    }

    private var isDelayedByAGestureRecognizer: Bool {
        viewDelivery == .pending && gestureRecognizers.contains {
            $0.delaysTouchesBegan && $0.state == .possible
        }
    }

    private func deliverToView(_ phase: UITouchPhase) {
        guard let view, let event else { return }
        switch phase {
        case .began:
            viewDelivery = .began
            view.touchesBegan([self], with: event)
        case .moved, .stationary:
            view.touchesMoved([self], with: event)
        case .ended:
            viewDelivery = .finished
            view.touchesEnded([self], with: event)
        case .cancelled:
            viewDelivery = .finished
            view.touchesCancelled([self], with: event)
        }
    }

    func cancelForViews() {
        if hasBeenCancelledByAGestureRecognizer { return }
        hasBeenCancelledByAGestureRecognizer = true
        delayedViewPhases = []
        if viewDelivery == .began { deliverToView(.cancelled) }
    }

    /// A recognizer that recognizes discards the touches it delayed.
    func discardDelayedViewTouches() {
        guard delayedViewPhases.first == .began else { return }
        delayedViewPhases.removeFirst()
        viewDelivery = .discarded
    }

    func flushDelayedViewTouches() {
        guard !isDelayedByAGestureRecognizer, !hasBeenCancelledByAGestureRecognizer else { return }
        let phases = delayedViewPhases
        delayedViewPhases = []
        phases.forEach(deliverToView)
    }
}

extension UITouch: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(touchId)
    }

    nonisolated public static func == (lhs: UITouch, rhs: UITouch) -> Bool {
        return lhs.touchId == rhs.touchId
    }
}

public enum UITouchPhase: Int {
    case began, moved, stationary, ended, cancelled
}

