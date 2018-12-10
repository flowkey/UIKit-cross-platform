//
//  UIViewAnimationGroup.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

/// Animations with the same animationGroup were created by the same UIView.animate call
class UIViewAnimationGroup {
    var completion: ((Bool) -> ())?
    var queuedAnimations = 0
    var options: UIView.AnimationOptions = []

    init(options: UIView.AnimationOptions, completion: ((Bool) -> Void)?) {
        self.options = options
        self.completion = completion
    }

    func animationDidStop(finished: Bool) {
        queuedAnimations -= 1
        if queuedAnimations == 0 {
            completion?(finished)
        }
    }
}

extension UIViewAnimationGroup: Hashable {
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    static func ==(lhs: UIViewAnimationGroup, rhs: UIViewAnimationGroup) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
