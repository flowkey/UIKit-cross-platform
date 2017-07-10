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

    private var currentControlState: UIControlState = .normal
    private var titleForControlState = [UIControlState: String]()
    private var titleColorForControlState = [UIControlState: UIColor]()
    private var titleShadowColorForControlState = [UIControlState: UIColor]()

    private var defaultLabelVerticalPadding: CGFloat = 6
    
    open func sizeToFit() {
        layoutSubviews()
        titleLabel?.sizeToFit()
        imageView?.sizeToFit()
        
        let imageSize = imageView?.frame.size ?? .zero
        let labelSize = titleLabel?.frame.size ?? .zero

        if imageView != nil {
            frame.width = imageSize.width + labelSize.width
            frame.height = max(imageSize.height, labelSize.height)
        } else {
            if titleLabel != nil {
                frame.width = labelSize.width
                frame.height = labelSize.height + 2 * defaultLabelVerticalPadding
            } else {
                frame.size = CGSize(width: 30, height: 34)
            }
        }
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
        if let titleForCurrentControlState = titleForControlState[currentControlState] {
            if titleLabel == nil { titleLabel = UILabel() }
            titleLabel?.text = titleForCurrentControlState
        }
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
            imageView?.frame.origin.x = 0
            titleLabel?.frame.origin.x = imageWidth
        case .right:
            imageView?.frame.maxX = bounds.maxX - labelWidth
            titleLabel?.frame.maxX = bounds.maxX
        }
        
        switch contentVerticalAlignment {
        case .center:
            imageView?.frame.midY = bounds.midY
            titleLabel?.frame.midY = bounds.midY
        case .top:
            if imageView == nil {
                titleLabel?.frame.origin.y = defaultLabelVerticalPadding
            } else {
                titleLabel?.frame.origin.y = 0
                imageView?.frame.origin.y = 0
            }
        case .bottom:
            if imageView == nil {
                titleLabel?.frame.origin.y = bounds.maxY - defaultLabelVerticalPadding
            } else {
                titleLabel?.frame.maxY = bounds.maxY
                imageView?.frame.maxY = bounds.maxY
            }
        }
    }
}

extension Button {
    public func setTitle(_ text: String, for state: UIControlState) {
        titleForControlState[state] = text
        layoutSubviews()
    }
    
    public func setTitleColor(_ color: UIColor, for state: UIControlState) {
        titleColorForControlState[state] = color
        layoutSubviews()
    }
    
    public func setTitleShadowColor(_ color: UIColor, for state: UIControlState) {
        titleShadowColorForControlState[state] = color
        layoutSubviews()
    }
}
