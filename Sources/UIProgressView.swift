//
//  UIProgressView.swift
//  UIKit
//
//  Created by Michael Knoch on 07.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIProgressView: UIView {
    let progressLayer = CALayer()
    open var progress: Float = 0 {
        didSet { setNeedsLayout() }
    }

    public var progressTintColor: UIColor? {
        didSet { progressLayer.backgroundColor = progressTintColor?.cgColor }
    }

    public var trackTintColor: UIColor? {
        didSet { backgroundColor = trackTintColor }
    }

    public func setProgress(_ progress: Float, animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        self.progress = progress
        CATransaction.commit()
    }

    public init() {
        super.init(frame: .zero)
        layer.addSublayer(progressLayer)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        progressLayer.frame = bounds
        progressLayer.cornerRadius = layer.cornerRadius
        progressLayer.frame.width = bounds.width * CGFloat(progress)
    }
}

