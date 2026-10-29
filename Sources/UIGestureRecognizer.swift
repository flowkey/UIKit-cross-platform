//
//  UIGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum UIGestureRecognizerState {
    case possible
    case began
    case changed
    case ended
    case cancelled
    case failed

    /// iOS's name for a tap's final state, since a tap has no began or changed to end. Same value as `ended`.
    /// https://developer.apple.com/documentation/uikit/uigesturerecognizer/state/recognized
    public static let recognized = UIGestureRecognizerState.ended
}

// Reference: https://developer.apple.com/documentation/uikit/uigesturerecognizer
// and https://developer.apple.com/documentation/uikit/about_the_gesture_recognizer_state_machine

@MainActor
open class UIGestureRecognizer {
    public var isEnabled = true {
        didSet {
            guard !isEnabled, !touches.isEmpty else { return }
            switch state {
            case .possible: transition(to: .failed)
            case .began, .changed: transition(to: .cancelled)
            case .ended, .cancelled, .failed: break
            }
        }
    }

    public weak var delegate: UIGestureRecognizerDelegate?
    public internal(set) weak var view: UIView?

    public var cancelsTouchesInView = true
    public var delaysTouchesBegan = false
    public var delaysTouchesEnded = true

    public typealias OnActionCallback = (@MainActor () -> Void)?
    internal var onAction: OnActionCallback

    public init(onAction: OnActionCallback = nil) {
        self.onAction = onAction
    }

    /// Every touch of the current sequence, including those that already ended, in the order they began.
    internal private(set) var touches: [UITouch] = []

    internal var activeTouches: [UITouch] {
        touches.filter { $0.phase != .ended && $0.phase != .cancelled }
    }

    public var numberOfTouches: Int { touches.count }

    public func location(ofTouch touchIndex: Int, in view: UIView?) -> CGPoint {
        touches[touchIndex].location(in: view)
    }

    /// The centroid of the touches, as on iOS.
    open func location(in view: UIView?) -> CGPoint {
        let activeTouches = activeTouches
        let relevantTouches = activeTouches.isEmpty ? touches : activeTouches
        guard !relevantTouches.isEmpty else { return .zero }
        let sum = relevantTouches.reduce(CGPoint.zero) { $0 + $1.location(in: view) }
        return sum / CGFloat(relevantTouches.count)
    }

    // MARK: State machine

    private var _state: UIGestureRecognizerState = .possible

    /// A recognition held back while a recognizer this one requires to fail is still undecided.
    private var pendingState: UIGestureRecognizerState?

    public var state: UIGestureRecognizerState {
        get { _state }
        set { request(newValue) }
    }

    private func request(_ newState: UIGestureRecognizerState) {
        if newState == _state, newState != .changed, pendingState == nil { return }

        if _state == .possible, newState == .began || newState == .ended {
            if let pendingState {
                // A continuous gesture that ends while still waiting never began.
                if pendingState == .began, newState == .ended { transition(to: .failed) }
                return
            }
            guard shouldBegin() else { return transition(to: .failed) }
            switch failureRequirementStatus() {
            case .unresolved: pendingState = newState
            case .recognized: transition(to: .failed)
            case .failed: transition(to: newState)
            }
            return
        }

        if pendingState != nil {
            switch newState {
            case .changed: return
            case .cancelled, .failed:
                transition(to: .failed)
            default: break
            }
            return
        }

        transition(to: newState)
    }

    private func transition(to newState: UIGestureRecognizerState) {
        let oldState = _state
        _state = newState

        if oldState == .possible, newState == .began || newState == .ended {
            preventOtherGestureRecognizers()
            for touch in touches {
                touch.discardDelayedViewTouches()
                if cancelsTouchesInView { touch.cancelForViews() } else { touch.flushDelayedViewTouches() }
            }
            dependents.forEach { $0.requirementRecognized() }
        }

        switch newState {
        case .began, .changed:
            onAction?()
        case .ended, .cancelled:
            onAction?()
            finish()
        case .failed:
            dependents.forEach { $0.requirementFailed() }
            finish()
        case .possible:
            break
        }
    }

    /// Stops receiving touches, but like iOS stays in its final state until the touch sequence ends.
    private func finish() {
        for touch in touches { touch.gestureRecognizers.removeAll { $0 === self } }
        pendingState = nil
        touches.forEach { $0.flushDelayedViewTouches() }

        let isSequenceOver = UIEvent.activeEvents.allSatisfy { event in
            event.allTouches?.allSatisfy { $0.phase == .ended || $0.phase == .cancelled } ?? true
        }
        if isSequenceOver {
            resetToPossible()
        } else {
            UIGestureRecognizer.recognizersAwaitingReset.append(self)
        }
    }

    private func resetToPossible() {
        touches = []
        _state = .possible
        reset()
    }

    private static var recognizersAwaitingReset: [UIGestureRecognizer] = []

    /// Called once every touch of the sequence has ended.
    internal static func resetFinishedRecognizers() {
        let recognizers = recognizersAwaitingReset
        recognizersAwaitingReset = []
        recognizers.forEach { $0.resetToPossible() }
    }

    private func shouldBegin() -> Bool {
        if let view, !view.gestureRecognizerShouldBegin(self) { return false }
        return delegate?.gestureRecognizerShouldBegin(self) ?? true
    }

    /// Resets the recognizer's own state once its gesture ended, failed or was cancelled.
    open func reset() {}

    // MARK: Failure requirements

    private var failureRequirements: [WeakGestureRecognizer] = []
    private var weakDependents: [WeakGestureRecognizer] = []
    private var dependents: [UIGestureRecognizer] { weakDependents.compactMap(\.value) }

    public func require(toFail other: UIGestureRecognizer) {
        failureRequirements.append(WeakGestureRecognizer(other))
        other.weakDependents.append(WeakGestureRecognizer(self))
    }

    private enum RequirementStatus { case unresolved, recognized, failed }

    private func failureRequirementStatus() -> RequirementStatus {
        var others = failureRequirements.compactMap(\.value)
        for touch in touches {
            for other in touch.gestureRecognizers where other !== self && !others.contains(where: { $0 === other }) {
                if delegate?.gestureRecognizer(self, shouldRequireFailureOf: other) == true
                    || other.delegate?.gestureRecognizer(other, shouldBeRequiredToFailBy: self) == true
                {
                    others.append(other)
                }
            }
        }

        var status = RequirementStatus.failed
        for other in others where !other.touches.isEmpty {
            switch other._state {
            case .began, .changed, .ended: return .recognized
            case .possible: status = .unresolved
            case .cancelled, .failed: break
            }
        }
        return status
    }

    private func requirementRecognized() {
        if pendingState != nil { transition(to: .failed) }
    }

    private func requirementFailed() {
        guard let pendingState else { return }
        switch failureRequirementStatus() {
        case .unresolved: return
        case .recognized:
            transition(to: .failed)
        case .failed:
            self.pendingState = nil
            transition(to: pendingState)
        }
    }

    // MARK: Simultaneous recognition

    private func preventOtherGestureRecognizers() {
        var prevented: [UIGestureRecognizer] = []
        for touch in touches {
            for other in touch.gestureRecognizers where other !== self && !prevented.contains(where: { $0 === other }) {
                if canRecognizeSimultaneously(with: other) { continue }
                prevented.append(other)
            }
        }

        for other in prevented {
            switch other._state {
            case .possible: other.transition(to: .failed)
            case .began, .changed: other.transition(to: .cancelled)
            case .ended, .cancelled, .failed: break
            }
        }
    }

    private func canRecognizeSimultaneously(with other: UIGestureRecognizer) -> Bool {
        delegate?.gestureRecognizer(self, shouldRecognizeSimultaneouslyWith: other) == true
            || other.delegate?.gestureRecognizer(other, shouldRecognizeSimultaneouslyWith: self) == true
    }

    // MARK: Touch delivery (called by UIWindow)

    internal func shouldReceive(_ touch: UITouch) -> Bool {
        let isFinished = _state == .ended || _state == .cancelled || _state == .failed
        return isEnabled && !isFinished && delegate?.gestureRecognizer(self, shouldReceive: touch) != false
    }

    internal var canTrackAnotherTouch: Bool { true }

    internal func add(_ touch: UITouch) {
        touches.append(touch)
        touch.gestureRecognizers.append(self)
    }

    internal func touchSequenceEnded() {
        guard activeTouches.isEmpty, !touches.isEmpty else { return }
        if _state == .possible, pendingState == nil { transition(to: .failed) }
    }

    /// A recognition still waiting for its requirements when the touches are gone never happens.
    internal func failIfStillPending() {
        if pendingState != nil, activeTouches.isEmpty { transition(to: .failed) }
    }

    open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {}
    open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {}
    open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {}

    open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = _state == .possible ? .failed : .cancelled
    }
}

internal struct WeakGestureRecognizer {
    weak var value: UIGestureRecognizer?
    init(_ value: UIGestureRecognizer) { self.value = value }
}

// Allow UIGestureRecognizers to be added to a `Set` etc.
extension UIGestureRecognizer: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    nonisolated public static func == (lhs: UIGestureRecognizer, rhs: UIGestureRecognizer) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
