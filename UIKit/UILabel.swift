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
    open var text: String?
    open var font: UIFont = .systemFont(ofSize: 12)
    open var textColor: UIColor!
    open var textAlignment: NSTextAlignment = .left
    open var numberOfLines: Int = 1
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    open func sizeToFit() {
        // implement to fit text width
    }
}
