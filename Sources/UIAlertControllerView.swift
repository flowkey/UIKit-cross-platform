//
//  UIAlertControllerView.swift
//  UIKit
//
//  Created by Geordie Jay on 25.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

private let verticalPadding: CGFloat = 18
private let horizontalPadding: CGFloat = 24
private let horizontalGap: CGFloat = 16

private let minWidth: CGFloat = 300 - 2 * horizontalPadding

private let maxWidth: CGFloat = {
    var result: CGFloat = 0
    if UIScreen.main.isPortrait {
        result = UIScreen.main.bounds.width - 2 * horizontalPadding
    } else {
        result = max(minWidth, min(UIScreen.main.bounds.width / 2, 500))
    }
    return result - 2 * horizontalPadding
}()


class UIAlertControllerView: UIView {
    let header = UILabel(frame: .zero)
    let text: UILabel?
    let style: UIAlertControllerStyle

    var buttons: [UIAlertControllerButton] = []
    var subviewWidth: CGFloat = minWidth

    init(
        title: String?,
        message: String?,
        actions: [UIAlertAction],
        style: UIAlertControllerStyle)
    {
        self.style = style
        header.text = title
        header.font = UIFont.systemFont(ofSize: 20)

        if let message = message {
            text = UILabel(frame: .zero)
            text?.numberOfLines = 0
            text?.text = message
            text?.font = UIFont.systemFont(ofSize: 16, weight: .light)
            text?.textColor = UIColor(hex: 0x3C3C43)
        } else {
            text = nil
        }

        super.init(frame: .zero)

        buttons = actions.map { action in
            let button = UIAlertControllerButton(frame: .zero)
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(UIColor(hex: 0x5856D6), for: .normal)
            button.setTitleColor(.black, for: .highlighted)

            button.onPress = { [weak self] in
                // Always dismiss the AlertController first so we're not trying to
                // present something on it that immediately gets dismissed again.
                (self?.next as? UIAlertController)?.dismiss(animated: true)
                action.handler?(action)
            }

            return button
        }

        clipsToBounds = true
        backgroundColor = .white
        layer.cornerRadius = 3

        header.numberOfLines = 0
        header.layer.contentsGravity = .top
        addSubview(header)
        text.map { addSubview($0) }
        buttons.forEach { addSubview($0) }

        subviewWidth = {
            guard let largestSubviewWidth = subviews.map({ $0.frame.width }).max() else {
                assertionFailure("no subviews exist to determine largestSubviewWidth")
                return minWidth
            }
            return min(maxWidth, max(largestSubviewWidth, minWidth))
        }()
    }

    override func layoutSubviews() {
        subviews.forEach { $0.sizeToFit() }

        header.frame.origin = CGPoint(x: horizontalPadding, y: verticalPadding)
        header.bounds.width = subviewWidth
        header.sizeToFit()

        // XXX: sizeToFit() seems to change the alignment, so we're explicitly reassigning it here
        header.textAlignment = .left

        if let text = text {
            text.frame.origin.x = horizontalPadding
            text.frame.width = subviewWidth 
            text.sizeToFit()
            text.frame.minY = header.frame.maxY + verticalPadding
        }

        if style == .alert {
            let totalButtonsWidth = buttons.reduce(0, { $0 + $1.frame.width }) + horizontalGap * CGFloat(buttons.count - 1)
            if totalButtonsWidth < subviewWidth {
                return layoutButtonsHorizontally()
            }
        }
        return layoutButtonsVertically()

    }

    private func layoutButtonsVertically() {
        buttons.enumerated().forEach({ (arg) in
            let (index, button) = arg

            let fullButtonWidth = subviewWidth + horizontalPadding * 2

            switch style {
            case .actionSheet:
                button.titleLabelOriginX = horizontalPadding
            case .alert:
                button.titleLabelOriginX = fullButtonWidth - horizontalPadding - button.bounds.width
            }

            button.frame.size.width = fullButtonWidth
            button.frame.size.height += verticalPadding

            if button == buttons.first {
                button.frame.minY = CGFloat(text?.frame.maxY ?? header.frame.maxY) + verticalPadding
            } else {
                let previousElement = buttons[index - 1]
                button.frame.origin.y = previousElement.frame.maxY
            }

        })
    }

    private func layoutButtonsHorizontally() {
        buttons.enumerated().forEach({ (arg) in
            let (index, button) = arg
            button.sizeToFit()
            button.clipsToBounds = true
            button.frame.width = max(button.frame.width, 75)
            button.contentHorizontalAlignment = .center
            button.frame.minY = CGFloat(text?.frame.maxY ?? header.frame.maxY) + verticalPadding
            if button == buttons.first {
                button.frame.origin.x = bounds.maxX - button.frame.width - horizontalGap
            } else {
                let previousElement = buttons[index - 1]
                button.frame.origin.x = previousElement.frame.minX - button.frame.width - horizontalGap
            }
        })
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        layoutIfNeeded()
        return CGSize(
            width: subviewWidth + horizontalPadding * 2,
            height: CGFloat(buttons.last?.frame.maxY ?? 0) + verticalPadding
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

private extension UIScreen {
    var isPortrait: Bool {
        return self.bounds.width < self.bounds.height
    }
}
