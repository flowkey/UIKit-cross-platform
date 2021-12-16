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
    let text: UITextView?
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

        if let message = message {
            text = UITextView(frame: .zero)
            text?.text = message
            text?.font = UIFont.systemFont(ofSize: 14)
        } else {
            text = nil
        }

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
        header.layer.contentsGravity = .top
        addSubview(header)
        text.map { addSubview($0) }

        buttons.forEach{ addSubview($0) }
    }

    override func layoutSubviews() {
        switch style {
        case .actionSheet: layoutAsActionSheet()
        case .alert: layoutAsAlert()
        }
    }

    private func layoutAsActionSheet() {
        header.frame.origin = CGPoint(x: horizontalPadding, y: verticalPadding)
        buttons.enumerated().forEach({ (arg) in
            let (index, button) = arg
            let previousElement = (index > 0) ? buttons[index - 1] : header
            button.sizeToFit()
            button.contentHorizontalAlignment = .left
            button.frame.size.height += verticalPadding
            button.frame.size.width = max(bounds.size.width, button.frame.size.width)
            button.frame.origin.y = (previousElement == header)
                ? previousElement.frame.maxY + verticalPadding
                : previousElement.frame.maxY
            button.titleLabelOriginX = horizontalPadding
        })
    }

    private func layoutAsAlert() {
        guard let text = text else {
            return
        }
        header.frame.origin = CGPoint(x: horizontalPadding, y: verticalPadding)
        text.frame.origin.x = horizontalPadding
        text.frame.width = UIScreen.main.bounds.width * 0.5
        text.sizeToFit()
        text.frame.minY = header.frame.maxY + verticalPadding
        buttons.enumerated().forEach({ (arg) in
            let (index, button) = arg
            button.sizeToFit()
            button.frame.width = max(button.frame.width, 75)
            button.contentHorizontalAlignment = .center
            button.frame.minY = text.frame.maxY + verticalPadding
            if button == buttons.first {
                button.frame.origin.x = bounds.maxX - button.frame.width - verticalPadding
            } else {
                let previousElement = buttons[index - 1]
                button.frame.origin.x = previousElement.frame.minX - button.frame.width - verticalPadding
            }
        })
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        layoutIfNeeded()
        
        let width: CGFloat
        let height: CGFloat
        
        switch style {
        case .actionSheet:
            width = buttons.map { $0.frame.width }.max()!
            height = buttons.last?.frame.maxY ?? header.frame.height
        case .alert:
            let buttonsWidth = buttons.reduce(0, { $0 + $1.frame.width + verticalPadding })
            width = ([header.frame.width, text?.frame.width ?? 0, buttonsWidth]).max()!
            height = buttons.first?.frame.maxY ?? text?.frame.height ?? 0
        }
        
        return CGSize(
            width: max(minWidth, width) + horizontalPadding,
            height: height + verticalPadding
        )
    }
}


class UIAlertControllerButton: Button {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.lightGray.withAlphaComponent(0.2) : .clear
        }
    }

    var titleLabelOriginX: CGFloat?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let titleLabelOriginX = titleLabelOriginX {
            titleLabel?.frame.origin.x = titleLabelOriginX
        }
    }
}
