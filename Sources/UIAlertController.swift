//
//  UIAlertController.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum UIAlertControllerStyle {
    case actionSheet
    case popover
    case alert
}

public class UIAlertController: UIViewController {
    override var animationTime: Double { return 0.3 }

    public var message: String?
    public let preferredStyle: UIAlertControllerStyle
    public private(set) var actions: [UIAlertAction] = []

    public init(title: String?, message: String?, preferredStyle: UIAlertControllerStyle) {
        self.message = message
        assert(message == nil, "We haven't implemented `message` yet")
        self.preferredStyle = preferredStyle
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    public func addAction(_ action: UIAlertAction) {
//        // if 'cancel' button has no handler fallback to self.dismiss (iOS behaviour)
//        if action.style == .cancel && action.handler == nil {
//            action.handler = { [weak self] _ in
//                self?.dismiss(animated: true, completion: nil)
//            }
//        }

        actions.append(action)
    }

    fileprivate var alertControllerView: UIAlertControllerView?

    override public func loadView() {
        self.view = UIView()

        let alertControllerView = UIAlertControllerView(
            title: self.title,
            message: self.message,
            actions: self.actions,
            style: preferredStyle
        )

        view.addSubview(alertControllerView)
        self.alertControllerView = alertControllerView
        alertControllerView.next = self
    }


    override func makeViewAppear(animated: Bool, presentingViewController: UIViewController) {
        presentingViewController.view.addSubview(view)
        alertControllerView?.sizeToFit()

        // Default is `nil`, meaning this wouldn't animate otherwise:
        self.view.backgroundColor = .clear

        UIView.animate(withDuration: animated ? animationTime * 1.5 : 0.0, animations: {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        })

        self.alertControllerView?.center = CGPoint(
            x: round(self.view.bounds.midX),
            y: round(self.view.bounds.midY)
        )
    }

    override func makeViewDisappear(animated: Bool, completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: animated ? animationTime : 0.0, animations: {
            view.alpha = 0
        }, completion: completion)
    }
}

private class UIAlertControllerView: UIView {
    let header = UILabel(frame: .zero)
    var buttons: [Button] = []
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
            let button = Button(frame: .zero)
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
        buttons.forEach{ $0.sizeToFit() }

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

    // TODO: to be adjusted
    private let verticalPadding: CGFloat = 20
    private let horizontalPadding: CGFloat = 20
    private let minWidth: CGFloat = 300

    private func layoutAsActionSheet() {
        header.frame.origin = CGPoint(x: horizontalPadding, y: verticalPadding)
        buttons.enumerated().forEach({ (arg) in
            let (index, button) = arg
            let previousElement = (index > 0) ? buttons[index - 1] : header
            button.frame.origin = CGPoint(
                x: horizontalPadding,
                y: previousElement.frame.maxY + verticalPadding
            )
        })
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let widestElement = buttons.max { a, b in a.frame.width < b.frame.width }
        let elementWidth = widestElement?.frame.width ?? header.frame.width

        let elementHeight = header.frame.height + buttons.reduce(0, { prev, next in return prev + next.frame.height })
        let paddingHeight = verticalPadding + CGFloat(buttons.count) * verticalPadding + verticalPadding

        return CGSize(
            width: max(minWidth, elementWidth) + 2 * horizontalPadding,
            height: elementHeight + paddingHeight
        )
    }
}
