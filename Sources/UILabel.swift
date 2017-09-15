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
        textLayer.texture = font.render(text, color: textColor, wrapLength: wrapLength)
        setNeedsLayout() // to realign text if needed
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(textLayer)
        isUserInteractionEnabled = false
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        self.draw()

        guard let texture = textLayer.texture else { return .zero }
        return texture.size
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
