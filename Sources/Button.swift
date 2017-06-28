//
//  Button.swift
//  NativePlayerSDL
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//


// Note: we deliberately don't wrap UIButton.
// This allows us to have a somewhat custom API free of objc selectors etc.

public enum ContentHorizontalAlignment {
    case center
    case left
    case right
}

public enum ContentVerticalAlignment {
    case center
    case top
    case bottom
}

open class Button: UIView {
    public var imageView: UIImageView?
    public var image: UIImage? {
        get {
            return imageView?.image
        }
        set {
            if imageView == nil {
                imageView = UIImageView()
            }
            imageView?.image = newValue
            imageView?.sizeToFit()
            if let imageView = imageView {
                addSubview(imageView)
            }
        }
    }
    
    public var titleLabel: UILabel? {
        didSet {
            oldValue?.removeFromSuperview()
            if let titleLabel = titleLabel {
                addSubview(titleLabel)
            }
        }
    }
    
    public func setTitleColor(color: UIColor) {
        titleLabel?.textColor = color
    }
    
    open var text: String? {
        get { return titleLabel?.text }
        set {
            if let text = newValue {
                if titleLabel == nil { titleLabel = UILabel() }
                titleLabel?.text = text
            } else {
                titleLabel = nil
            }
        }
    }
    
    open var horizontalPadding = 8.0
    open var verticalPadding = 5.0
    
    open var contentHorizontalAlignment: ContentHorizontalAlignment = .center
    open var contentVerticalAlignment: ContentVerticalAlignment = .center
    
    public let tapGestureRecognizer = UITapGestureRecognizer()
    public var onPress: (() -> Void)? {
        didSet { tapGestureRecognizer.onPress = onPress }
    }

    open func sizeToFit() {
        bounds.size = image?.size ?? .zero
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        tapGestureRecognizer.view = self
        addGestureRecognizer(tapGestureRecognizer)
    }
}
