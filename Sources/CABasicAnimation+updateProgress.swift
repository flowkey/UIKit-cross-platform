//
//  CABasicAnimation+updateProgress.swift
//  UIKit
//
//  Created by Michael Knoch on 21.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CABasicAnimation {
    func progress(for currentTime: Timer) -> CGFloat {
        let elapsedTimeInMs = max(CGFloat(currentTime - timer) - (delay * 1000), 0)
        let durationInMs = duration * 1000

        // prevents a division by zero when animating with duration: 0
        // additionally we have to check elapsedTime because of a potential delay
        if elapsedTimeInMs > 0 && durationInMs <= 0 {
            return 1
        }

        let linearProgress = min(elapsedTimeInMs / (durationInMs), 1)
        return ease(x: linearProgress)
    }

    private func ease(x: CGFloat) -> CGFloat {
        return timingFunction?[at: x] ?? x
    }
}

