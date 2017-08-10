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
    var layersWithAnimations = Set<CALayer>()

    init(completion: ((Bool) -> Void)?) {
        self.completion = completion
    }

    func didStop(finished: Bool) {
        queuedAnimations -= 1
        if queuedAnimations == 0 {
            completion?(finished)
            remove()
        }
    }
}

extension UIViewAnimationGroup: Equatable {
    static func ==(lhs: UIViewAnimationGroup, rhs: UIViewAnimationGroup) -> Bool {
        return ObjectIdentifier(lhs).hashValue == ObjectIdentifier(rhs).hashValue
    }

    func remove() {
        UIView.animationGroups = UIView.animationGroups.filter { $0 != self }
    }
}
