//
//  Button.swift
//  NativePlayerSDL
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

// Note: we deliberately don't wrap UIButton.
// This allows us to have a somewhat custom API free of objc selectors etc.

open class Button: UIControl {
    public var imageView: UIImageView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let imageView = imageView { addSubview(imageView) }
        }
    }
    public var image: UIImage? {
        get { return imageView?.image }
        set {
            guard let image = newValue else { imageView = nil; return }

            if imageView == nil { imageView = UIImageView() }
            imageView?.image = image
            imageView?.sizeToFit()
        }
    }
    
    public var titleLabel: UILabel? {
        didSet {
            oldValue?.removeFromSuperview()
            if let titleLabel = titleLabel { addSubview(titleLabel) }
        }
    }
    open var text: String? {
        get { return titleLabel?.text }
        set {
            guard let text = newValue else { titleLabel = nil; return }

            if titleLabel == nil { titleLabel = UILabel() }
            titleLabel?.text = text
        }
    }

    private var currentControlState: UIControlState = .normal
    private var titleForControlState = [UIControlState: String]()
    private var titleColorForControlState = [UIControlState: UIColor]()
    private var titleShadowColorForControlState = [UIControlState: UIColor]()
    
    open var contentEdgeInsets = UIEdgeInsets() {
        didSet { layoutSubviews() }
    }
    
    open func sizeToFit() {
        layoutSubviews()
        titleLabel?.sizeToFit()
        imageView?.sizeToFit()
        
        let imageSize = imageView?.frame.size ?? .zero
        let labelSize = titleLabel?.frame.size ?? .zero
        
        frame.width = imageSize.width + labelSize.width + contentEdgeInsets.left + contentEdgeInsets.right
        frame.height = max(imageSize.height, labelSize.height) + contentEdgeInsets.top + contentEdgeInsets.bottom
    }
    
    public let tapGestureRecognizer = UITapGestureRecognizer()
    public var onPress: (() -> Void)? {
        didSet { tapGestureRecognizer.onPress = onPress }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        tapGestureRecognizer.view = self
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    open override func layoutSubviews() {
        titleLabel?.text = titleForControlState[currentControlState]
        if let titleColorForCurrentControlState = titleColorForControlState[currentControlState] {
            titleLabel?.textColor = titleColorForCurrentControlState
        }
        if let titleShadowColorForCurrentControlState = titleColorForControlState[currentControlState] {
            titleLabel?.shadowColor = titleShadowColorForCurrentControlState
        }

        titleLabel?.layoutSubviews()
        
        let imageWidth = imageView?.frame.width ?? 0
        let labelWidth = titleLabel?.frame.width ?? 0
        
        switch contentHorizontalAlignment {
        case .center:
            imageView?.frame.midX = bounds.midX - labelWidth / 2
            titleLabel?.frame.midX = bounds.midX + imageWidth / 2
        case .left:
            imageView?.frame.origin.x = contentEdgeInsets.left
            titleLabel?.frame.origin.x = imageWidth + contentEdgeInsets.left
        case .right:
            imageView?.frame.maxX = bounds.maxX - labelWidth - contentEdgeInsets.right
            titleLabel?.frame.maxX = bounds.maxX - contentEdgeInsets.right
        }
        
        switch contentVerticalAlignment {
        case .center:
            imageView?.frame.midY = bounds.midY
            titleLabel?.frame.midY = bounds.midY
        case .top:
            imageView?.frame.origin.y = contentEdgeInsets.top
            titleLabel?.frame.origin.y = contentEdgeInsets.top
        case .bottom:
            imageView?.frame.maxY = bounds.maxY - contentEdgeInsets.bottom
            titleLabel?.frame.maxY = bounds.maxY - contentEdgeInsets.bottom
        }
    }
}

extension Button {
    public func setTitle(_ text: String, for state: UIControlState) {
        titleForControlState[state] = text
    }
    
    public func setTitleColor(_ color: UIColor, for state: UIControlState) {
        titleColorForControlState[state] = color
    }
    
    public func setTitleShadowColor(_ color: UIColor, for state: UIControlState) {
        titleShadowColorForControlState[state] = color
    }
}
