//
//  UIView+CALayerDelegate.swift
//  UIKit
//
//  Created by Michael Knoch on 31.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension UIView: CALayerDelegate {
    open func action(forKey event: String) -> CABasicAnimation? {
        guard let prototype = UIView.currentAnimationPrototype else { return nil }

        let keyPath = AnimationKeyPath(stringLiteral: event)
        let beginFromCurrentState = prototype.animationGroup.options.contains(.beginFromCurrentState)
        let state = beginFromCurrentState ? (layer.presentation ?? layer) : layer

        if let fromValue = state.value(forKeyPath: keyPath) {
            return prototype.createAnimation(keyPath: keyPath, fromValue: fromValue)
        }

        return nil
    }
}

public protocol CALayerDelegate {
    func action(forKey event: String) -> CABasicAnimation?
}
