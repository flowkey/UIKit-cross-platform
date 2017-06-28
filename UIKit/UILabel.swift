//
//  UILabel.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum NSTextAlignment {
    case center
    case left
    case right
}

open class UILabel: UIView {
    public var numberOfLines: Int = 1 {
        didSet { setNeedsDisplay() }
    }

    public var textColor: UIColor = .black {
        didSet { setNeedsDisplay() }
    }

    public var textAlignment: NSTextAlignment = .left {
        didSet { setNeedsLayout() }
    }

    public let textLayer = CALayer()

    public var text: String? {
        didSet { setNeedsDisplay() }
    }

    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet { setNeedsDisplay() }
    }

    override open var frame: CGRect {
        didSet { if oldValue.size != frame.size { setNeedsDisplay() } }
    }

    open override func draw() {
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0
        textLayer.texture = font.render(text, color: textColor, wrapLength: wrapLength)
        layoutSubviews()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(textLayer)
    }

    open func sizeToFit() {
        // XXX: We should take numberOfLines into account here!
        bounds.size = text?.size(with: self.font) ?? .zero
    }

    open override func layoutSubviews() {
        switch textAlignment {
        case .left: textLayer.frame.origin = .zero
        case .center: textLayer.frame.midX = bounds.midX
        case .right: textLayer.frame.maxX = bounds.maxX
        }
    }
}
