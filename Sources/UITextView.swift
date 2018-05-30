//
//  UITextView.swift
//  UIKit
//
//  Created by Michael Knoch on 11.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UITextView: UIScrollView {
    private var label = UILabel()
    public var isEditable = false
    public var isSelectable = false

    public var textColor: UIColor {
        get { return label.textColor }
        set { label.textColor = newValue }
    }

    public var text: String? {
        get { return label.text }
        set {
            label.text = newValue
            contentOffset = .zero // scroll to top left when new text is set
            setNeedsLayout()
        }
    }

    public var attributedText: NSAttributedString? {
        get { return label.attributedText }
        set {
            label.attributedText = newValue
            setNeedsLayout()
        }
    }

    public var font: UIFont {
        get { return label.font }
        set {
            label.font = newValue
            setNeedsLayout()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.numberOfLines = 0
        label.layer.contentsGravityEnum = .topLeft
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        label.frame.width = bounds.width
        return label.sizeThatFits(size)
    }

    private let spaceToVerticalScrollIndicator: CGFloat = 17.5

    override open func layoutSubviews() {
        label.frame.width = bounds.width - spaceToVerticalScrollIndicator
        label.sizeToFit()
        label.frame.origin = .zero

        let textHeight = label.frame.height
        contentSize = CGSize(width: bounds.width, height: max(textHeight, bounds.height))
    }
}
