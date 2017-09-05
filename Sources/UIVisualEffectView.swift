//
//  UIVisualEffectView.swift
//  UIKit
//
//  Created by Chris on 29.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIVisualEffectView: UIView {
    public init(effect: UIVisualEffect) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        // mocked to be always of style dark
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
    }
}
