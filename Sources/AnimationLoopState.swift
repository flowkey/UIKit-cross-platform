//
//  AnimationLoopState.swift
//  UIKit
//
//  Created by Michael Knoch on 17.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

/// Represents the state of an animation loop and is used to determine
/// if an animatableProperty has changed twice during one loop.
struct AnimationLoopState {
    var frame = false
    var bounds = false
    var opacity = false

    subscript(animationProperty: AnimationProperty) -> Bool {
        get {
            switch animationProperty {
            case .bounds: return self.bounds
            case .frame: return self.frame
            case .opacity: return self.opacity
            case .unknown: return false // throw error?
            }
        }
        set {
            switch animationProperty {
            case .bounds: self.bounds = newValue
            case .frame: self.frame  = newValue
            case .opacity: self.opacity = newValue
            case .unknown: break
            }
        }
    }
}
