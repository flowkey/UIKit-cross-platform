//
//  UIViewAnimationGroup.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class UIViewAnimationGroup: CABasicAnimationDelegate {
    var completion: ((Bool) -> ())?
    var queuedAnimations = 0

    init(completion: ((Bool) -> Void)?) {
        self.completion = completion
    }

    func didStop(finished: Bool) {
        queuedAnimations -= 1
        if queuedAnimations == 0 {
            completion?(finished)
            UIView.animationGroups.remove(self)
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
