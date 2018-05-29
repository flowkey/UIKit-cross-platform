//
//  UILabel.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum NSTextAlignment: Int {
    case center
    case left
    case right

    internal func contentsGravity() -> CALayer.ContentsGravity {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
}

open class UILabel: UIView {
    public var numberOfLines: Int = 1 {
        didSet { if numberOfLines != oldValue { setNeedsDisplay() } }
    }
    
    public var text: String? {
        didSet { if text != oldValue { setNeedsDisplay() } }
    }

    public var attributedText: NSAttributedString? {
        didSet {
            text = attributedText?.string
            setNeedsDisplay()
        }
    }

    public var textColor: UIColor = .black {
        didSet { if textColor != oldValue { setNeedsDisplay() } }
    }

    public var textAlignment: NSTextAlignment = .left {
        didSet { updateLayerContentsGravityFromTextAlignment() }
    }

    private func updateLayerContentsGravityFromTextAlignment() {
        layer.contentsGravityEnum = textAlignment.contentsGravity()
    }

    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet { if font != oldValue { setNeedsDisplay() } }
    }

    override open var frame: CGRect {
        didSet { if oldValue.size != frame.size { setNeedsDisplay() } }
    }

    open override func draw() {
        super.draw()
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0

        if let attributedText = attributedText {
            layer.contents = font.render(attributedText, color: textColor, wrapLength: wrapLength)
        } else {
            layer.contents = font.render(text, color: textColor, wrapLength: wrapLength)
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        updateLayerContentsGravityFromTextAlignment()
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let text = self.attributedText?.string ?? self.text else { return .zero }
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0

        if let attributedText = attributedText {
            return attributedText.size(with: self.font, wrapLength: wrapLength)
        }

        return text.size(with: self.font, wrapLength: wrapLength)
    }

    open var shadowColor: UIColor? {
        get { return layer.shadowColor }
        set { layer.shadowColor = newValue?.cgColor }
    }
}
