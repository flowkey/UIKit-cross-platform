//
//  UIViewAnimationGroup.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

class UIViewAnimationGroup {

    var completion: ((Bool) -> ())?
    var animations = [CABasicAnimation]()

    func didStopAnimation(animation: CABAsicAnimation, finished: Bool) {
        animations = animations.filter({ $0 != animation })
        if animations.isEmpty {
            completion(finished)
        }
    }

    init(completion: ((Bool) -> ())?) {
        self.completion = completion
    }
    
}
