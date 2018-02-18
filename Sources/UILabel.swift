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

    public var attributedText: NSAttributedString? {
        didSet {
            text = attributedText?.string
            // TODO: also set textColor etc according to attributes
            setNeedsDisplay()
        }
    }

    public var textColor: UIColor = .black {
        didSet { setNeedsDisplay() }
    }

    public var textAlignment: NSTextAlignment = .left {
        didSet { setNeedsLayout() }
    }

    public let textLayer = CALayer()
    
    public var shadowColor: UIColor? {
        get { return textLayer.shadowColor }
        set { textLayer.shadowColor = newValue?.cgColor }
    }

    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet { setNeedsDisplay() }
    }

    override open var frame: CGRect {
        didSet { if oldValue.size != frame.size { setNeedsDisplay() } }
    }

    open override func draw() {
        super.draw()
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.contents = font.render(text, color: textColor, wrapLength: wrapLength)
        setNeedsLayout() // to realign text if needed
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(textLayer)
        isUserInteractionEnabled = false
        textLayer.disableAnimations = true
        textLayer.contentsGravity = "center"
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let text = self.text else { return .zero }
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0
        return text.size(with: self.font, wrapLength: UInt(wrapLength))
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        switch textAlignment {
        case .left:
            textLayer.frame.minX = bounds.minX
        case .center:
            textLayer.frame.midX = bounds.midX
        case .right:
            textLayer.frame.maxX = bounds.maxX
        }
    }
}
