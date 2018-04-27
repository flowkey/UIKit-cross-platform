//
//  UIAlertControllerView.swift
//  UIKit
//
//  Created by Geordie Jay on 25.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

private let verticalPadding: CGFloat = 18
private let horizontalPadding: CGFloat = 24
private let minWidth: CGFloat = 300

class UIAlertControllerView: UIView {
    let header = UILabel(frame: .zero)
    var buttons: [UIAlertControllerButton] = []
    let style: UIAlertControllerStyle

    init(
        title: String?,
        message: String?,
        actions: [UIAlertAction],
        style: UIAlertControllerStyle)
    {
        self.style = style
        header.text = title
        header.font = UIFont.boldSystemFont(ofSize: 20)

        super.init(frame: .zero)

        buttons = actions.map { action in
            let button = UIAlertControllerButton(frame: .zero)
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(UIColor(hex: 0x757575), for: .normal) // color from react-native settings menu
            button.setTitleColor(.black, for: .highlighted)

            button.onPress = { [weak self] in
                // Always dismiss the AlertController first so we're not trying to
                // present something on it that immediately gets dismissed again.
                (self?.next as? UIAlertController)?.dismiss(animated: true)
                action.handler?(action)
            }

            return button
        }

        backgroundColor = .white
        layer.cornerRadius = 3

        header.sizeToFit()
        header.frame.height += verticalPadding
        header.layer.contentsGravityEnum = .top
        addSubview(header)

        buttons.forEach{ addSubview($0) }
    }

    override func layoutSubviews() {
        switch style {
        case .actionSheet: layoutAsActionSheet()
        default: assertionFailure(
            "The UIAlertControllerStyle style, \(style), is not implemented yet!")
        }
    }

    private func layoutAsActionSheet() {
        header.frame.origin = CGPoint(x: horizontalPadding, y: verticalPadding)
        buttons.enumerated().forEach({ (arg) in
            let (index, button) = arg
            let previousElement = (index > 0) ? buttons[index - 1] : header
            button.sizeToFit()
            button.contentHorizontalAlignment = .left
            button.bounds.size.height += verticalPadding
            button.frame.size.width = max(bounds.size.width, button.frame.size.width)
            button.frame.origin = CGPoint(x: 0, y: previousElement.frame.maxY)
        })
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        layoutIfNeeded()

        let widestElement = buttons.max { a, b in a.frame.width < b.frame.width }
        let elementWidth = widestElement?.frame.width ?? header.frame.width
        let elementHeight = header.frame.height + buttons.reduce(0, { $0 + $1.bounds.height })

        return CGSize(
            width: max(minWidth, elementWidth) + horizontalPadding, // on right
            height: elementHeight + verticalPadding * 2 // at bottom
        )
    }
}


class UIAlertControllerButton: Button {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.lightGray.withAlphaComponent(0.2) : .clear
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel?.frame.origin.x = horizontalPadding
    }
}
