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
    var layers = [CALayer]()

    func didStop(finished: Bool) {
        queuedAnimations -= 1

        if queuedAnimations == 0 {
            completion?(finished)
        }
    }

    init(completion: ((Bool) -> ())?) {
        self.completion = completion
    }
    
}
