//
//  UIView+CALayerDelegate.swift
//  UIKit
//
//  Created by Michael Knoch on 31.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension UIView: CALayerDelegate {
    func action(forKey event: String) -> CABasicAnimation? {
        let keyPath = AnimationKeyPath(stringLiteral: event)

        let beginFromCurrentState = UIView.currentAnimationPrototype?.options.contains(.beginFromCurrentState) ?? false
        let state = beginFromCurrentState ? (layer.presentation ?? layer) : layer

        if
            let fromValue = state.value(forKeyPath: keyPath),
            let prototype = UIView.currentAnimationPrototype
        {
            return prototype.createAnimation(keyPath: keyPath, fromValue: fromValue)
        }

        return nil
    }
}

protocol CALayerDelegate {
    func action(forKey event: String) -> CABasicAnimation?
}
