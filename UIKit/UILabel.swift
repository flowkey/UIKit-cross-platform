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
    open var textColor: UIColor = .black
    open var textAlignment: NSTextAlignment = .left
    open var numberOfLines: Int = 1
    
    private let textLayer = CALayer()
    
    open var text: String? {
        didSet {
            renderText()
        }
    }
    open var font: UIFont = .systemFont(ofSize: 12) {
        didSet {
            renderText()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    private func renderText() {
        let wrapLength = numberOfLines > 0 ? bounds.width : 0
        textLayer.texture = font.render(text, color: textColor, wrapLength: wrapLength)
    }
    
    open func sizeToFit() {
        // implement to fit text width
    }
}
