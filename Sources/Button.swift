//
//  Button.swift
//  NativePlayerSDL
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

// Note: we deliberately don't wrap UIButton.
// This allows us to have a somewhat custom API free of objc selectors etc.

fileprivate let labelVerticalPadding: CGFloat = 6

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

    private var sizeToFitWasCalled = false

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        sizeToFitWasCalled = true
        updateLabelAndImageForCurrentState()
        titleLabel?.sizeToFit()
        imageView?.sizeToFit()
        setNeedsLayout()

        if let imageView = imageView, let titleLabel = titleLabel {
            return CGSize(
                width: imageView.frame.width + titleLabel.frame.width,
                height: max(imageView.frame.height, titleLabel.frame.height)
            )
        } else if let imageView = imageView, titleLabel == nil {
            return CGSize(width: imageView.frame.width, height: imageView.frame.height)
        } else if let titleLabel = titleLabel, imageView == nil {
            return CGSize(
                width: titleLabel.frame.width,
                height: titleLabel.frame.height + (2 * labelVerticalPadding)
            )
        } else {
            return CGSize(width: 30, height: 34)
        }
    }

    public let tapGestureRecognizer = UITapGestureRecognizer()
    public var onPress: (() -> Void)? {
        get { return tapGestureRecognizer.onPress }
        set { tapGestureRecognizer.onPress = newValue }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        tapGestureRecognizer.view = self
        addGestureRecognizer(tapGestureRecognizer)
    }

    fileprivate var images = [UIControlState: UIImage]()
    fileprivate var attributedTitles = [UIControlState: NSAttributedString]()
    fileprivate var titles = [UIControlState: String]()
    fileprivate var titleColors = [UIControlState: UIColor]()
    fileprivate var titleShadowColors = [UIControlState: UIColor]()
    
    open override func layoutSubviews() {
        updateLabelAndImageForCurrentState()

        if let titleColor = titleColors[state], titleLabel?.attributedText == nil {
            titleLabel?.textColor = titleColor
        }

        if let titleShadowColor = titleShadowColors[state], titleLabel?.attributedText == nil{
            titleLabel?.shadowColor = titleShadowColor
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
                titleLabel?.frame.origin.y = sizeToFitWasCalled ? labelVerticalPadding : 0
            } else {
                titleLabel?.frame.origin.y = 0
                imageView?.frame.origin.y = 0
            }
        case .bottom:
            if imageView == nil {
                titleLabel?.frame.maxY = bounds.maxY - (sizeToFitWasCalled ? labelVerticalPadding : 0)
            } else {
                titleLabel?.frame.maxY = bounds.maxY
                imageView?.frame.maxY = bounds.maxY
            }
        }

        super.layoutSubviews()
    }
}

extension Button {
    fileprivate func updateLabelAndImageForCurrentState() {
        if let attributedTitleForCurrentState = attributedTitles[state] {
            titleLabel?.attributedText = attributedTitleForCurrentState
        } else if let titleForCurrentState = titles[state] {
            titleLabel?.text = titleForCurrentState
        } else if let attributedTitleForNormalState = attributedTitles[.normal] {
            titleLabel?.attributedText = attributedTitleForNormalState
        } else if let titleForNormalState = titles[.normal] {
            titleLabel?.text = titleForNormalState
        }

        if let imageForCurrentState = images[state] {
            imageView?.image = imageForCurrentState
        } else if let imageForNormalState = images[.normal] {
            imageView?.image = imageForNormalState
        }
    }
}

extension Button {
    public func setImage(_ image: UIImage?, for state: UIControlState) {
        images[state] = image
        createOrRemoveImageViewIfNeeded()
        setNeedsLayout()
    }

    public func setTitle(_ text: String?, for state: UIControlState) {
        titles[state] = text
        createOrRemoveLabelIfNeeded()
        setNeedsLayout()
    }

    public func setAttributedTitle(_ attributedText: NSAttributedString?, for state: UIControlState) {
        attributedTitles[state] = attributedText
        createOrRemoveLabelIfNeeded()
        setNeedsLayout()
    }

    private func createOrRemoveLabelIfNeeded() {
        if attributedTitles.isEmpty && titles.isEmpty {
            titleLabel = nil
        } else if titleLabel == nil {
            titleLabel = UILabel()
        }
    }

    private func createOrRemoveImageViewIfNeeded() {
        if images.isEmpty {
            imageView = nil
        } else if imageView == nil {
            imageView = UIImageView()
        }
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
