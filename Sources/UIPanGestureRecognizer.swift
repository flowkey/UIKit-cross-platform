//
//  UIPanGestureRecognizer.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIPanGestureRecognizer: UIGestureRecognizer {
    public var minimumNumberOfTouches = 1
    public var maximumNumberOfTouches = Int.max

    private let hysteresis: CGFloat = 10
    private let velocitySampleDuration: Double = 0.1

    /// Where the translation is measured from, in window coordinates.
    private var translationOrigin: CGPoint?
    private var samples: [(location: CGPoint, timestamp: Double)] = []

    override var canTrackAnotherTouch: Bool {
        activeTouches.count < maximumNumberOfTouches
    }

    open func translation(in view: UIView?) -> CGPoint {
        guard let translationOrigin, !touches.isEmpty else { return .zero }
        return convert(location(in: nil), to: view) - convert(translationOrigin, to: view)
    }

    open func setTranslation(_ translation: CGPoint, in view: UIView?) {
        guard !touches.isEmpty else { return }
        let origin = convert(location(in: nil), to: view) - translation
        translationOrigin = view?.convert(origin, to: nil) ?? origin
    }

    open func velocity(in view: UIView?) -> CGPoint {
        guard let last = samples.last, let first = samples.first(where: { last.timestamp - $0.timestamp <= velocitySampleDuration }) else {
            return .zero
        }
        let duration = last.timestamp - first.timestamp
        guard duration > 0 else { return .zero }
        return (convert(last.location, to: view) - convert(first.location, to: view)) / CGFloat(duration)
    }

    private func convert(_ windowPoint: CGPoint, to view: UIView?) -> CGPoint {
        view?.convert(windowPoint, from: nil) ?? windowPoint
    }

    private func recordSample(at timestamp: Double) {
        samples.append((location(in: nil), timestamp))
        samples.removeAll { timestamp - $0.timestamp > velocitySampleDuration * 2 }
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if translationOrigin == nil {
            translationOrigin = location(in: nil)
        } else {
            keepTranslation(whileTouchesChange: touches, joined: true)
        }
        touches.first.map { recordSample(at: $0.timestamp) }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        touches.first.map { recordSample(at: $0.timestamp) }

        switch state {
        case .possible:
            if activeTouches.count >= minimumNumberOfTouches, translation(in: nil).magnitude >= hysteresis {
                state = .began
            }
        case .began, .changed:
            state = .changed
        case .ended, .cancelled, .failed:
            break
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        if !activeTouches.isEmpty { keepTranslation(whileTouchesChange: touches, joined: false) }
        touches.first.map { recordSample(at: $0.timestamp) }
        guard activeTouches.isEmpty, state == .began || state == .changed else { return }
        state = .ended
    }

    /// Moves the origin with the centroid when a finger joins or lifts, so the translation and velocity don't jump.
    private func keepTranslation(whileTouchesChange changedTouches: Set<UITouch>, joined: Bool) {
        let touchesAfter = activeTouches
        let touchesBefore = joined ? touchesAfter.filter { !changedTouches.contains($0) } : touchesAfter + changedTouches
        guard let translationOrigin, !touchesBefore.isEmpty, !touchesAfter.isEmpty else { return }
        self.translationOrigin = translationOrigin + centroid(of: touchesAfter) - centroid(of: touchesBefore)
        samples = []
    }

    private func centroid(of touches: [UITouch]) -> CGPoint {
        touches.reduce(CGPoint.zero) { $0 + $1.location(in: nil) } / CGFloat(touches.count)
    }

    open override func reset() {
        super.reset()
        translationOrigin = nil
        samples = []
    }
}
