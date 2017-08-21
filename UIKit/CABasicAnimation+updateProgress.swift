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
        progress = min(elapsedTime / (duration * 1000), 1).ease(options: self.options)
        return progress
    }
}

fileprivate extension CGFloat {
    func ease(options: UIViewAnimationOptions) -> CGFloat {
        if options.contains(.curveEaseIn) { return easeInQuad(at: self) }
        if options.contains(.curveEaseOut) { return easeOutQuad(at: self) }
        if options.contains(.curveEaseInOut) { return easeInOutCubic(at: self) }
        return self
    }
}

private func easeInQuad(at x: CGFloat) -> CGFloat { return pow(x, 2) }
private func easeInCubic(at x: CGFloat) -> CGFloat { return pow(x, 3) }
private func easeOutQuad(at x: CGFloat) -> CGFloat { return x * (2-x) }
private func easeOutCubic(at x: CGFloat) -> CGFloat { return x * (2-x) }
private func easeInOutCubic(at x: CGFloat) -> CGFloat { return x < 0.5 ? 4*pow(x,3) : (x-1)*(2*x-2)*(2*x-2)+1 }
