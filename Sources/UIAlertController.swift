//
//  UIAlertController.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum UIAlertControllerStyle {
    case actionSheet
//    case alert // not needed right now
}

public class UIAlertController: UIViewController {
    public var message: String?
    public let preferredStyle: UIAlertControllerStyle
    public private(set) var actions: [UIAlertAction]

    public init(title: String?, message: String?, preferredStyle: UIAlertControllerStyle) {
        self.message = message // TODO: currently never used
        self.preferredStyle = preferredStyle // TODO: currently never used
        self.actions = []
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    public func addAction(_ action: UIAlertAction) {
        // if 'cancel' button has no handler fallback to self.dismiss (iOS behaviour)
        if action.style == .cancel && action.handler == nil {
            action.handler = { _ in self.dismiss(animated: true, completion: nil) }
        }

        actions.append(action)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadView()
    }

    override public func dismiss(animated: Bool, completion: (() -> Void)?) {
        super.dismiss(animated: animated, completion: completion)
    }

    override public func loadView() {
        self.view = UIAlertControllerView(
            title: self.title,
            message: self.message,
            actions: self.actions,
            style: preferredStyle
        )
        self.view.sizeToFit()
        self.view.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    }

}

private class UIAlertControllerView: UIView {
    let header: UILabel
    let elements: [Button]
    let style: UIAlertControllerStyle

    init(title: String?, message: String?, actions: [UIAlertAction], style: UIAlertControllerStyle) {
        self.style = style

        header = UILabel(frame: .zero)
        header.text = title
        header.font = UIFont.boldSystemFont(ofSize: 20)

        elements = actions.map { action in
            let button = Button(frame: .zero)
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(UIColor(hex: 0x757575), for: .normal)  // color picked from react-native settings menu
            button.setTitleColor(.black, for: .highlighted)
            button.onPress = { // TODO: do we need a closure capture list?
                action.handler?(action)
            }
            return button
        }

        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 3

        header.sizeToFit()
        elements.forEach{ $0.sizeToFit() }

        addSubview(header)
        elements.forEach{ addSubview($0) }
    }

    override func layoutSubviews() {
        switch style {
        case .actionSheet: layoutAsActionSheet()
        }
    }


    // TODO: to be adjusted
    private let verticalPadding: CGFloat = 20
    private let horizontalPadding: CGFloat = 20
    private let minWidth: CGFloat = 300

    private func layoutAsActionSheet() {
        header.frame.origin = CGPoint(x: horizontalPadding, y: verticalPadding)
        elements.enumerated().forEach({ (arg) in
            let (index, element) = arg
            let previousElement = (index > 0) ? elements[index-1] : header
            element.frame.origin = CGPoint(
                x: horizontalPadding,
                y: previousElement.frame.maxY + verticalPadding
            )
        })
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let widestElement = elements.max { a, b in a.frame.width < b.frame.width }
        let elementWidth = widestElement?.frame.width ?? header.frame.width

        let elementHeight = header.frame.height + elements.reduce(0, { prev, next in return prev + next.frame.height })
        let paddingHeight = verticalPadding + CGFloat(elements.count) * verticalPadding + verticalPadding

        let size = CGSize(
            width: max(minWidth, elementWidth) + 2 * horizontalPadding,
            height: elementHeight + paddingHeight
        )

        return size
    }

}

public enum UIModalPresentationStyle {
    case popover
    case formSheet
    // TODO: add others
}
