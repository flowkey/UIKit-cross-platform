//
//  CABasicAnimation+updateProgress.swift
//  UIKit
//
//  Created by Michael Knoch on 21.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CABasicAnimation {
    func progress(for currentTime: Timer) -> CGFloat {
        let elapsedTimeMinusDelayInMs = max(CGFloat(currentTime - creationTime) - (delay * 1000), 0)
        let durationInMs = duration * 1000
        let animationHasStarted = elapsedTimeMinusDelayInMs > 0

        // prevents a division by zero when animating with duration: 0
        if animationHasStarted && durationInMs <= 0 {
            return 1
        }

        let linearProgress = min(elapsedTimeMinusDelayInMs / (durationInMs), 1)
        return ease(x: linearProgress)
    }

    private func ease(x: CGFloat) -> CGFloat {
        return timingFunction?[at: x] ?? x
    }
}

