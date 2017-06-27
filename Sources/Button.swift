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
        layoutSubviews()
        titleLabel?.sizeToFit()
        
        let imageSize = imageView?.frame.size ?? .zero
        let labelSize = titleLabel?.frame.size ?? .zero
        
        frame.width = imageSize.width + labelSize.width + 2 * horizontalPadding
        frame.height = max(imageSize.height, labelSize.height) + 2 * verticalPadding
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        tapGestureRecognizer.view = self
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    public func setTitleColor(color: UIColor) {
        // TODO: add attribute parameter to set different colors for each attribute
        titleLabel?.textColor = color
    }
    
    open override func layoutSubviews() {
        titleLabel?.layoutSubviews()
        
        let imageWidth = imageView?.frame.width ?? 0
        let labelWidth = titleLabel?.frame.width ?? 0
        
        switch contentHorizontalAlignment {
        case .center:
            imageView?.frame.midX = bounds.midX - labelWidth / 2
            titleLabel?.frame.midX = bounds.midX + imageWidth / 2
        case .left:
            imageView?.frame.origin.x = 0 + horizontalPadding
            titleLabel?.frame.origin.x = 0 + imageWidth + horizontalPadding
        case .right:
            imageView?.frame.maxX = bounds.maxX - labelWidth - horizontalPadding
            titleLabel?.frame.maxX = bounds.maxX - horizontalPadding
        }
        
        switch contentVerticalAlignment {
        case .center:
            imageView?.frame.midY = bounds.midY
            titleLabel?.frame.midY = bounds.midY
        case .top:
            imageView?.frame.origin.y = 0 + verticalPadding
            titleLabel?.frame.origin.y = 0 + verticalPadding
        case .bottom:
            imageView?.frame.maxY = bounds.maxY - verticalPadding
            titleLabel?.frame.maxY = bounds.maxY - verticalPadding
        }
    }
}
