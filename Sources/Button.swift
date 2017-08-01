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
    internal (set) public var imageView: UIImageView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let imageView = imageView { addSubview(imageView) }
        }
    }
    
    internal (set) public var titleLabel: UILabel? {
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

        let imageViewIsVisible = !(imageView?.isHidden ?? true)
        let titleLabelIsVisible = !(titleLabel?.isHidden ?? true)

        if imageViewIsVisible, titleLabelIsVisible {
            return CGSize(
                width: imageView!.frame.width + titleLabel!.frame.width,
                height: max(imageView!.frame.height, titleLabel!.frame.height)
            )
        } else if imageViewIsVisible, !titleLabelIsVisible {
            return CGSize(width: imageView!.frame.width, height: imageView!.frame.height)
        } else if titleLabelIsVisible, !imageViewIsVisible {
            return CGSize(
                width: titleLabel!.frame.width,
                height: titleLabel!.frame.height + (2 * labelVerticalPadding)
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

        titleLabel = UILabel()
        titleLabel?.isHidden = true

        imageView = UIImageView()
        imageView?.isHidden = true
        
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

        let titleLabelIsVisible = !(titleLabel?.isHidden ?? true)

        // titleColor and titleShadowColor for state only affects non-attributed text
        if titleLabelIsVisible, titleLabel?.attributedText == nil {
            if let titleColorForCurrentState = titleColors[state] {
                titleLabel?.textColor = titleColorForCurrentState
            } else if let titleColorForNormalState = titleColors[.normal] {
                titleLabel?.textColor = titleColorForNormalState
            }
            if let titleShadowColorForCurrentState = titleShadowColors[state] {
                titleLabel?.shadowColor = titleShadowColorForCurrentState
            } else if let titleShadowColorForNormalState = titleShadowColors[.normal] {
                titleLabel?.shadowColor = titleShadowColorForNormalState
            }
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
            if (imageView?.isHidden ?? true) {
                titleLabel?.frame.origin.y = sizeToFitWasCalled ? labelVerticalPadding : 0
            } else {
                titleLabel?.frame.origin.y = 0
                imageView?.frame.origin.y = 0
            }
        case .bottom:
            if (imageView?.isHidden ?? true) {
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
        imageView?.isHidden = (image == nil)
        setNeedsLayout()
    }

    public func setTitle(_ text: String?, for state: UIControlState) {
        titles[state] = text
        titleLabel?.isHidden = (text == nil)
        setNeedsLayout()
    }

    public func setAttributedTitle(_ attributedText: NSAttributedString?, for state: UIControlState) {
        attributedTitles[state] = attributedText
        titleLabel?.isHidden = (attributedText == nil)
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
