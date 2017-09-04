//
//  CALayer+copy.swift
//  UIKit
//
//  Created by Michael Knoch on 24.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CALayer {
    func copy(disableAnimations: Bool = false) -> CALayer {
        let copy = CALayer(layer: self)
        copy.disableAnimations = disableAnimations
        return copy
    }

    convenience init(layer: CALayer) {
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
    }
}
