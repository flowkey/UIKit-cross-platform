//
//  UIView+CALayerDelegate.swift
//  UIKit
//
//  Created by Michael Knoch on 31.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension UIView: CALayerDelegate {
    func action(forKey event: AnimationProperty) -> CABasicAnimation? {

        let beginFromCurrentState = UIView.currentAnimationPrototype?.options.contains(.beginFromCurrentState) ?? false
        let state = beginFromCurrentState ? (layer.presentation ?? layer) : layer

        if
            let fromValue = state.value(forKeyPath: event),
            let prototype = UIView.currentAnimationPrototype
        {
            return prototype.createAnimation(keyPath: event, fromValue: fromValue)
        }

        return nil
    }
}

protocol CALayerDelegate {
    func action(forKey event: AnimationProperty) -> CABasicAnimation?
}
