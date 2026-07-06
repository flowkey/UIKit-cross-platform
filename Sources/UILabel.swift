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

    internal func contentsGravity() -> CALayerContentsGravity {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
}

public enum NSLineBreakMode: Int {
    case byTruncatingTail
}

@MainActor
open class UILabel: UIView {
    open var numberOfLines: Int = 1 {
        didSet { if numberOfLines != oldValue { setNeedsDisplay() } }
    }
    
    open var text: String? {
        didSet { if text != oldValue { setNeedsDisplay() } }
    }

    /// Multi-font inline text (e.g. a bold label + regular value). When set, takes precedence
    /// over `text`/`font` for both sizing and drawing. Only the `.font` attribute is honoured.
    open var attributedText: NSAttributedString? {
        didSet { setNeedsDisplay() }
    }

    open var textColor: UIColor = .black {
        didSet { if textColor != oldValue { setNeedsDisplay() } }
    }

    open var textAlignment: NSTextAlignment = .left {
        didSet { updateLayerContentsGravityFromTextAlignment() }
    }

    open var lineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet { if lineBreakMode != oldValue { setNeedsDisplay() } }
    }

    private func updateLayerContentsGravityFromTextAlignment() {
        layer.contentsGravity = textAlignment.contentsGravity()
    }

    open var font: UIFont = .systemFont(ofSize: 16) {
        didSet { if font != oldValue { setNeedsDisplay() } }
    }

    override open var frame: CGRect {
        didSet { if oldValue.size != frame.size { setNeedsDisplay() } }
    }

    /// Wrap width in device pixels for the attributed-text path (0 = single line = no wrapping).
    private var attributedWrapLength: Int {
        Int((numberOfLines != 1 ? bounds.width : 0) * UIScreen.lastKnownScreenScale)
    }

    open override func draw() {
        super.draw()
        if let attributedText = attributedText {
            layer.contents = FontRenderer.renderAttributedString(attributedText, color: textColor, wrapLength: attributedWrapLength, alignment: textAlignment, defaultFont: font)
            return
        }
        // Single-line, tail-truncating labels get a trailing ellipsis to fit their width, matching
        // UIKit's default behaviour instead of overflowing/clipping.
        if numberOfLines == 1, lineBreakMode == .byTruncatingTail, let text = text, bounds.width > 0, let renderer = font.fontRenderer {
            let truncated = renderer.truncateTextIfNeeded(text, wrapLength: Int(bounds.width * UIScreen.lastKnownScreenScale))
            layer.contents = font.render(truncated, color: textColor, wrapLength: 0, alignment: textAlignment)
            return
        }

        let wrapLength = (numberOfLines != 1) ? bounds.width : 0
        layer.contents = font.render(text, color: textColor, wrapLength: wrapLength, alignment: textAlignment)
    }

    override open func display(_ layer: CALayer) {
        self.draw()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        updateLayerContentsGravityFromTextAlignment()
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        if let attributedText = attributedText {
            return FontRenderer.getAttributedStringSize(attributedText, wrapLength: attributedWrapLength, defaultFont: font) / UIScreen.lastKnownScreenScale
        }

        guard let text = self.text else { return .zero }
        let wrapLength = (numberOfLines != 1) ? bounds.width : 0

        return text.size(with: self.font, wrapLength: wrapLength)
    }

    open var shadowColor: UIColor? {
        get { return layer.shadowColor }
        set { layer.shadowColor = newValue?.cgColor }
    }
}
