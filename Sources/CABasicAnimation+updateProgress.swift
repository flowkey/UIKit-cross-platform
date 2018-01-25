//
//  CABasicAnimation+updateProgress.swift
//  UIKit
//
//  Created by Michael Knoch on 21.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CABasicAnimation {
    func progress(for currentTime: Timer) -> CGFloat {
        let elapsedTimeInMs = max(CGFloat(currentTime - self.timer) - (delay * 1000), 0)
        let durationInMs = duration * 1000

        if durationInMs - elapsedTimeInMs <= 0 {
            return 1
        }

        let linearProgress = min(elapsedTimeInMs / (durationInMs), 1)
        return ease(x: linearProgress)
    }

    private func ease(x: CGFloat) -> CGFloat {
        return timingFunction?[at: x] ?? x
    }
}

