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

    private let defaultLabelVerticalPadding: CGFloat = 6

    open func sizeToFit() {
        setNeedsLayout()
        titleLabel?.sizeToFit()
        imageView?.sizeToFit()

        if let imageView = imageView {
            frame.width = imageView.frame.width
            frame.height = imageView.frame.height
            if let titleLabel = titleLabel {
                frame.width += titleLabel.frame.width
                frame.height = max(imageView.frame.height, titleLabel.frame.height)
            }
        } else if let titleLabel = titleLabel {
            frame.width = titleLabel.frame.width
            frame.height = titleLabel.frame.height + 2 * defaultLabelVerticalPadding
        } else {
            frame.size = CGSize(width: 30, height: 34)
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

    private var images = [UIControlState: UIImage]()
    private var titles = [UIControlState: String]()
    private var titleColors = [UIControlState: UIColor]()
    private var titleShadowColors = [UIControlState: UIColor]()
    
    open override func layoutSubviews() {
        // Only change subview attributes if a corresponding entry exists in our dictionaries:

        if let titleForCurrentControlState = titles[state] {
            if titleLabel == nil { titleLabel = UILabel() }
            titleLabel?.text = titleForCurrentControlState
        } else if titles.isEmpty {
            titleLabel = nil
        }

        if let imageForCurrentControlState = images[state] {
            image = imageForCurrentControlState
        } else if images.isEmpty {
            image = nil
        }

        if let titleColorForCurrentControlState = titleColors[state] {
            titleLabel?.textColor = titleColorForCurrentControlState
        }

        if let titleShadowColorForCurrentControlState = titleShadowColors[state] {
            titleLabel?.shadowColor = titleShadowColorForCurrentControlState
        }

        titleLabel?.setNeedsLayout()

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
                titleLabel?.frame.maxY = bounds.maxY - defaultLabelVerticalPadding
            } else {
                titleLabel?.frame.maxY = bounds.maxY
                imageView?.frame.maxY = bounds.maxY
            }
        }

        super.layoutSubviews()
    }
}

extension Button {
    public func setImage(_ image: UIImage?, for state: UIControlState) {
        images[state] = image
        if images.isEmpty {
            imageView = nil
        } else if imageView == nil {
            imageView = UIImageView()
        }
        setNeedsLayout()
    }

    public func setTitle(_ text: String?, for state: UIControlState) {
        titles[state] = text
        if titles.isEmpty {
            titleLabel = nil
        } else if titleLabel == nil {
            titleLabel = UILabel()
        }
        setNeedsLayout()
    }

    public func setTitleColor(_ color: UIColor, for state: UIControlState) {
        titleColors[state] = color
        setNeedsLayout()
    }

    public func setTitleShadowColor(_ color: UIColor, for state: UIControlState) {
        titleShadowColors[state] = color
        setNeedsLayout()
    }
}
