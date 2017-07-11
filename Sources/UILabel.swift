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
    
    public var text: String? {
        didSet { setNeedsDisplay() }
    }

    public var textColor: UIColor = .black {
        didSet { setNeedsDisplay() }
    }

    public var textAlignment: NSTextAlignment = .left {
        didSet { setNeedsLayout() }
    }

    public let textLayer = CALayer()
    
    public var shadowColor: UIColor?

    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet { setNeedsDisplay() }
    }

    override open var frame: CGRect {
        didSet { if oldValue.size != frame.size { setNeedsDisplay() } }
    }

    open override func draw() {
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0
        textLayer.texture = font.render(text, color: textColor, wrapLength: wrapLength)
        textLayer.shadowColor = shadowColor?.cgColor
        setNeedsLayout()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(textLayer)
    }

    open func sizeToFit() {
        // XXX: We should take numberOfLines into account here!
        guard let text = self.text else { return }
        let previousFrame = self.frame
        bounds.size = text.size(with: self.font)
        layout(&frame, in: previousFrame) // uses text alignment to adjust self.frame
        setNeedsLayout()
    }

    open override func layoutSubviews() {
        layout(&textLayer.frame, in: self.bounds)
        super.layoutSubviews()
    }

    private func layout(_ rect: inout CGRect, in bounds: CGRect) {
        switch textAlignment {
        case .left: rect.minX = bounds.minX
        case .center: rect.midX = bounds.midX
        case .right: rect.maxX = bounds.maxX
        }
    }
}
