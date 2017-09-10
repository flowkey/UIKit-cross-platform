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
        self.progress = progress
    }

    public init() {
        super.init(frame: .zero)
        layer.addSublayer(progressLayer)
    }

    override open func layoutSubviews() {
        progressLayer.frame = bounds
        progressLayer.frame.width = bounds.width * CGFloat(progress)
        super.layoutSubviews()
    }
}

