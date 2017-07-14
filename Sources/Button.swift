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
    
    public var titleLabel: UILabel? {
        didSet {
            oldValue?.removeFromSuperview()
            if let titleLabel = titleLabel { addSubview(titleLabel) }
        }
    }

    private var currentLabelVerticalPadding: CGFloat = 0
    private let labelVerticalPaddingAfterSizeToFit: CGFloat = 6

    open func sizeToFit() {
        currentLabelVerticalPadding = labelVerticalPaddingAfterSizeToFit
        setNeedsLayout()
        titleLabel?.sizeToFit()
        imageView?.sizeToFit()

        if let imageView = imageView, let titleLabel = titleLabel {
            frame.width += titleLabel.frame.width
            frame.height = max(imageView.frame.height, titleLabel.frame.height)
        } else if let imageView = imageView, titleLabel == nil {
            frame.width = imageView.frame.width
            frame.height = imageView.frame.height
        } else if let titleLabel = titleLabel, imageView == nil {
            frame.width = titleLabel.frame.width
            frame.height = titleLabel.frame.height + (2 * labelVerticalPaddingAfterSizeToFit)
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
    private var attributedTitles = [UIControlState: NSAttributedString]()
    private var titles = [UIControlState: String]()
    private var titleColors = [UIControlState: UIColor]()
    private var titleShadowColors = [UIControlState: UIColor]()
    
    open override func layoutSubviews() {
        // Only change subview attributes if a corresponding entry exists in our dictionaries:

        if let attributedTitleForCurrentState = attributedTitles[state] {
            if titleLabel == nil { titleLabel = UILabel() }
            titleLabel?.attributedText = attributedTitleForCurrentState
        } else if let titleForCurrentState = titles[state] {
            if titleLabel == nil { titleLabel = UILabel() }
            titleLabel?.text = titleForCurrentState
        } else if titles.isEmpty && attributedTitles.isEmpty {
            titleLabel = nil
        }

        if let imageForCurrentState = images[state] {
            imageView?.image = imageForCurrentState
        } else if images.isEmpty {
            imageView = nil
        }

        if let titleColorForCurrentState = titleColors[state] {
            titleLabel?.textColor = titleColorForCurrentState
        }

        if let titleShadowColorForCurrentState = titleShadowColors[state] {
            titleLabel?.shadowColor = titleShadowColorForCurrentState
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
                titleLabel?.frame.origin.y = currentLabelVerticalPadding
            } else {
                titleLabel?.frame.origin.y = 0
                imageView?.frame.origin.y = 0
            }
        case .bottom:
            if imageView == nil {
                titleLabel?.frame.maxY = bounds.maxY - currentLabelVerticalPadding
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
        } else {
            if imageView == nil { imageView = UIImageView() }
            imageView?.image = image
        }
        setNeedsLayout()
    }

    public func setTitle(_ text: String?, for state: UIControlState) {
        titles[state] = text
        if titleLabel == nil { titleLabel = UILabel() }
        setNeedsLayout()
    }

    public func setAttributedTitle(_ attributedText: NSAttributedString?, for state: UIControlState) {
        attributedTitles[state] = attributedText
        if titleLabel == nil { titleLabel = UILabel() }
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
