//
//  UILabel.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum NSTextAlignment: String {
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
            text = attributedText?.string // TODO: also set textColor etc according to attributes
        }
    }

    public var textColor: UIColor = .black {
        didSet { setNeedsDisplay() }
    }

    public var textAlignment: NSTextAlignment = .left {
        didSet { updateLayerContentsGravityFromTextAlignment() }
    }

    private func updateLayerContentsGravityFromTextAlignment() {
        layer.contentsGravity = textAlignment.rawValue
    }

    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet { setNeedsDisplay() }
    }

    override open var frame: CGRect {
        didSet {
            if oldValue.size != frame.size { setNeedsDisplay() }
        }
    }

    open override func draw() {
        super.draw()
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0
        layer.contents = font.render(text, color: textColor, wrapLength: wrapLength)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        updateLayerContentsGravityFromTextAlignment()
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let text = self.text else { return .zero }
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0
        return text.size(with: self.font, wrapLength: wrapLength)
    }

    open var shadowColor: UIColor? {
        get { return layer.shadowColor }
        set { layer.shadowColor = newValue?.cgColor }
    }
}
