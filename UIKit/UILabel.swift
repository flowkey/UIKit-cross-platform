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
    open var numberOfLines: Int = 1
    open var textColor: UIColor = .black
    open var textAlignment: NSTextAlignment = .left {
        didSet {
            switch textAlignment {
            case .left: textLayer.frame.origin = .zero
            case .center: textLayer.frame.midX = bounds.midX
            case .right: textLayer.frame.maxX = bounds.maxX
            }
        }
    }

    private let textLayer = CALayer()

    open var text: String? {
        didSet { renderText() }
    }

    open var font: UIFont = .systemFont(ofSize: 16) {
        didSet { renderText() }
    }

    override open var frame: CGRect {
        didSet { if oldValue.size != frame.size { renderText() } }
    }

    private func renderText() {
        let wrapLength = (numberOfLines > 0) ? bounds.width : 0
        textLayer.texture = font.render(text, color: textColor, wrapLength: wrapLength)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(textLayer)
    }

    open func sizeToFit() {
        self.bounds.size = self.text?.size(with: self.font) ?? .zero
    }
}
