//
//  CABasicAnimation+updateProgress.swift
//  UIKit
//
//  Created by Michael Knoch on 21.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CABasicAnimation {
    func updateProgress(to currentTime: Timer) -> CGFloat {
        let elapsedTime = max(CGFloat(currentTime - self.timer) - (delay * 1000), 0)
        progress = ease(
            min(elapsedTime / (duration * 1000), 1),
            animationOptions: self.options
        )
        return progress
    }
}

private func ease(_ x: CGFloat, animationOptions: UIViewAnimationOptions) -> CGFloat {
    if animationOptions.contains(.curveEaseIn) { return easeInQuad(at: x) }
    if animationOptions.contains(.curveEaseOut) { return easeOutQuad(at: x) }
    if animationOptions.contains(.curveEaseInOut) { return easeInOutCubic(at: x) }
    return x
}

private func easeInQuad(at x: CGFloat) -> CGFloat { return pow(x, 2) }
private func easeInCubic(at x: CGFloat) -> CGFloat { return pow(x, 3) }
private func easeOutQuad(at x: CGFloat) -> CGFloat { return x * (2-x) }
private func easeOutCubic(at x: CGFloat) -> CGFloat { return x * (2-x) }
private func easeInOutCubic(at x: CGFloat) -> CGFloat { return x < 0.5 ? 4*pow(x,3) : (x-1)*(2*x-2)*(2*x-2)+1 }

