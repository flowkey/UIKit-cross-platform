//
//  UIPinchGestureRecognizer.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIPinchGestureRecognizer: UIGestureRecognizer {
    public typealias OnPinchCallback = (() -> Void)?
    internal var onPinch: OnPinchCallback
    public var scale: CGFloat = 1

    public init(onPinch: OnPinchCallback) {
        self.onPinch = onPinch
    }
}
