//
//  CALayer+createNonAnimatingCopy.swift
//  UIKit
//
//  Created by Michael Knoch on 24.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CALayer {
    func createNonAnimatingCopy() -> CALayer {
        return CALayer(layer: self, disableAnimations: true)
    }

    convenience init(layer: CALayer, disableAnimations: Bool) {
        self.init()
        frame = layer.frame
        bounds = layer.bounds
        opacity = layer.opacity
        backgroundColor = layer.backgroundColor
        isHidden = layer.isHidden
        cornerRadius = layer.cornerRadius
        borderWidth = layer.borderWidth
        borderColor = layer.borderColor
        shadowColor = layer.shadowColor
        shadowPath = layer.shadowPath
        shadowOffset = layer.shadowOffset
        shadowRadius = layer.shadowRadius
        shadowOpacity = layer.shadowOpacity
        texture = layer.texture
        sublayers = layer.sublayers
        self.disableAnimations = disableAnimations
    }
}
