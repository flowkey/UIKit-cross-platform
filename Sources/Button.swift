//
//  Button.swift
//  UIKit
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

// Note: we deliberately don't wrap UIButton.
// This allows us to have a somewhat custom API free of objc selectors etc.

fileprivate let labelVerticalPadding: CGFloat = 6

@MainActor
open class Button: UIControl {
    internal(set) public var imageView: UIImageView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let imageView = imageView { addSubview(imageView) }
        }
    }

    internal(set) public var titleLabel: UILabel? {
        didSet {
            oldValue?.removeFromSuperview()
            if let titleLabel = titleLabel { addSubview(titleLabel) }
        }
    }

    /// iOS strangely has different behaviour in layoutSubviews depending on whether sizeToFit was (ever) called beforehand
    private var sizeToFitWasCalled = false

    override open var isSelected: Bool {
        didSet { self.setNeedsLayout() }
    }

    open override var tintColor: UIColor! {
        didSet {
            if tintColor != nil { setTitleColor(tintColor, for: .normal) }
        }
    }

    override open func sizeToFit() {
        updateLabelAndImageForCurrentState()
        sizeToFitWasCalled = true

        imageView?.sizeToFit()
        titleLabel?.sizeToFit()

        super.sizeToFit()
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let titleLabel = titleLabel, let imageView = imageView else {
            assertionFailure("titleLabel or imageView should always exist in UIKit-SDL Button")
            return size
        }

        let imageViewIsVisible = !imageView.isHidden
        let titleLabelIsVisible = !titleLabel.isHidden

        if imageViewIsVisible, titleLabelIsVisible {
            return CGSize(
                width: imageView.frame.width + titleLabel.frame.width,
                height: max(imageView.frame.height, titleLabel.frame.height)
            )
        } else if imageViewIsVisible, !titleLabelIsVisible {
            return CGSize(width: imageView.frame.width, height: imageView.frame.height)
        } else if titleLabelIsVisible, !imageViewIsVisible {
            return CGSize(
                width: titleLabel.frame.width,
                height: titleLabel.frame.height + (2 * labelVerticalPadding)
            )
        } else {
            return CGSize(width: 30, height: 34)
        }
    }

    public let tapGestureRecognizer: UITapGestureRecognizer
    public var onPress: (@MainActor () -> Void)? {
        get { return tapGestureRecognizer.onPress }
        set { tapGestureRecognizer.onPress = newValue }
    }

    @MainActor
    public override init(frame: CGRect) {
        tapGestureRecognizer = UITapGestureRecognizer(onPress: nil)
        super.init(frame: frame)

        let titleLabel = UILabel(frame: .zero)
        titleLabel.isHidden = true
        addSubview(titleLabel)
        setTitleColor(.white, for: .normal)
        self.titleLabel = titleLabel

        let imageView = UIImageView(frame: .zero)
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        self.imageView = imageView

        tapGestureRecognizer.onTouchesBegan = { [weak self] in
            self?.isHighlighted = true
        }
        
        tapGestureRecognizer.onTouchesEnded = { [weak self] in
            self?.isHighlighted = false
        }

        tapGestureRecognizer.view = self
        addGestureRecognizer(tapGestureRecognizer)
    }

    fileprivate var images = [UIControlState: UIImage]()
    fileprivate var titles = [UIControlState: String]()
    fileprivate var titleColors = [UIControlState: UIColor]()
    fileprivate var titleShadowColors = [UIControlState: UIColor]()
    
    open override func layoutSubviews() {
        updateLabelAndImageForCurrentState()

        guard let titleLabel = titleLabel, let imageView = imageView else {
            assertionFailure("titleLabel or imageView should always exist in UIKit-SDL Button")
            return
        }

        let titleLabelIsVisible = !titleLabel.isHidden

        if titleLabelIsVisible {
            if let titleColorForCurrentState = titleColors[state] {
                titleLabel.textColor = titleColorForCurrentState
            } else if let titleColorForNormalState = titleColors[.normal] {
                titleLabel.textColor = titleColorForNormalState
            }
            if let titleShadowColorForCurrentState = titleShadowColors[state] {
                titleLabel.shadowColor = titleShadowColorForCurrentState
            } else if let titleShadowColorForNormalState = titleShadowColors[.normal] {
                titleLabel.shadowColor = titleShadowColorForNormalState
            }
        }

        titleLabel.setNeedsLayout()

        let imageWidth = imageView.frame.width
        let labelWidth = titleLabel.frame.width

        switch contentHorizontalAlignment {
        case .center:
            imageView.frame.midX = bounds.midX - (labelWidth / 2)
            titleLabel.frame.midX = bounds.midX + (imageWidth / 2)
        case .left:
            imageView.frame.origin.x = 0
            titleLabel.frame.origin.x = imageWidth
        case .right:
            imageView.frame.maxX = bounds.maxX - labelWidth
            titleLabel.frame.maxX = bounds.maxX
        }

        switch contentVerticalAlignment {
        case .center:
            imageView.frame.midY = bounds.midY
            titleLabel.frame.midY = bounds.midY
        case .top:
            if imageView.isHidden {
                titleLabel.frame.origin.y = sizeToFitWasCalled ? labelVerticalPadding : 0
            } else {
                titleLabel.frame.origin.y = 0
                imageView.frame.origin.y = 0
            }
        case .bottom:
            if imageView.isHidden {
                titleLabel.frame.maxY = bounds.maxY - (sizeToFitWasCalled ? labelVerticalPadding : 0)
            } else {
                titleLabel.frame.maxY = bounds.maxY
                imageView.frame.maxY = bounds.maxY
            }
        }

        super.layoutSubviews()
    }
}

extension Button {
    fileprivate func updateLabelAndImageForCurrentState() {
        if let titleForCurrentState = titles[state] {
            titleLabel?.text = titleForCurrentState
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

    public func setTitleColor(_ color: UIColor, for state: UIControlState) {
        titleColors[state] = color
        setNeedsLayout()
    }

    public func setTitleShadowColor(_ color: UIColor, for state: UIControlState) {
        titleShadowColors[state] = color
        setNeedsLayout()
    }
}
