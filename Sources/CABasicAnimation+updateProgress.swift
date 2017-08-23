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
        let linearProgress = min(elapsedTime / (duration * 1000), 1)

        self.progress = ease(x: linearProgress)
        return progress
    }

    fileprivate func ease(x: CGFloat) -> CGFloat {
        return timingFunction?.compute(x: x) ?? x
    }
}
