//
//  CABasicAnimation+updateProgress.swift
//  UIKit
//
//  Created by Michael Knoch on 21.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CABasicAnimation {
    func progress(for currentTime: Timer) -> CGFloat {
        let elapsedTimeMinusDelayInMs = CGFloat(currentTime - creationTime) - (delay * 1000)

        // prevents a division by zero when animating with duration: 0
        if duration <= 0 {
            let animationHasStarted = (elapsedTimeMinusDelayInMs > 0)
            return animationHasStarted ? 1.0 : 0.0
        }

        let durationInMs = duration * 1000
        let linearProgress = max(0, min(1, elapsedTimeMinusDelayInMs / durationInMs))
        return ease(x: linearProgress)
    }

    private func ease(x: CGFloat) -> CGFloat {
        return timingFunction?[at: x] ?? x
    }
}

