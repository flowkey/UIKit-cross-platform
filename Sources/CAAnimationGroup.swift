//
//  CAAnimationGroup.swift
//  UIKit
//
//  Created by Michael Knoch on 31.08.26.
//  Copyright © 2026 flowkey. All rights reserved.
//

public class CAAnimationGroup: CABasicAnimation {
    public var animations: [CABasicAnimation]?

    public override init() {
        super.init()
    }

    init(from animation: CAAnimationGroup) {
        animations = animation.animations
        super.init(from: animation)
    }

    override func copy() -> CAAnimationGroup {
        return CAAnimationGroup(from: self)
    }

    func groupedAnimations() -> [CABasicAnimation] {
        return (animations ?? []).map { animation in
            let copy = animation.copy()
            copy.delay += delay
            if duration > 0 {
                copy.duration = min(copy.duration, duration)
            }
            return copy
        }
    }
}
