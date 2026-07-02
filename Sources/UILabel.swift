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

@MainActor
open class UILabel: UIView {
    open var numberOfLines: Int = 1 {
        didSet { if numberOfLines != oldValue { setNeedsDisplay() } }
    }
    
    open var text: String? {
        didSet { if text != oldValue { setNeedsDisplay() } }
    }

    /// Multi-font inline text (e.g. a bold label + regular value). When set, takes precedence
    /// over `text`/`font` for both sizing and drawing.
    open var styledRuns: [StyledTextRun]? {
        didSet { setNeedsDisplay() }
    }

    open var textColor: UIColor = .black {
        didSet { if textColor != oldValue { setNeedsDisplay() } }
    }

    open var textAlignment: NSTextAlignment = .left {
        didSet { updateLayerContentsGravityFromTextAlignment() }
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

    open override func draw() {
        super.draw()
        if let styledRuns = styledRuns {
            let wrapLength = Int((numberOfLines != 1 ? bounds.width : 0) * UIScreen.main.scale)
            layer.contents = FontRenderer.renderStyledRuns(styledRuns, color: textColor, wrapLength: wrapLength, alignment: textAlignment)
            return
        }
        // Single-line labels truncate with a trailing ellipsis to fit their width (like iOS'
        // default `.byTruncatingTail`), instead of overflowing/clipping.
        if numberOfLines == 1, let text = text, bounds.width > 0, let renderer = font.fontRenderer {
            let truncated = renderer.truncatedText(text, toWidth: Int(bounds.width * UIScreen.main.scale))
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
        if let styledRuns = styledRuns {
            let wrapLength = Int((numberOfLines != 1 ? bounds.width : 0) * UIScreen.main.scale)
            return FontRenderer.styledRunsSize(styledRuns, wrapLength: wrapLength) / UIScreen.main.scale
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
