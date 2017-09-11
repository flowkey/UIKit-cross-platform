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
        clipsToBounds = true
    }

    override open func layoutSubviews() {
        label.sizeToFit()
        label.frame.size = bounds.size

        let textHeight: CGFloat = 520 // xxx: get this from label when multiline sizeToFit is fixed
        contentSize = CGSize(width: bounds.width, height: textHeight)
        backgroundColor = UIColor.red.withAlphaComponent(0.1)

        super.layoutSubviews()
    }
}
