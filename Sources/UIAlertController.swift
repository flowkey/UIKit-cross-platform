//
//  UIAlertController.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import func Foundation.round

public enum UIAlertControllerStyle {
    case actionSheet
    case alert
}

public class UIAlertController: UIViewController {
    override var animationTime: Double { return 0.3 }

    open var message: String?
    public let preferredStyle: UIAlertControllerStyle
    public private(set) var actions: [UIAlertAction] = []

    public init(title: String?, message: String?, preferredStyle: UIAlertControllerStyle) {
        self.message = message
        self.preferredStyle = preferredStyle
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    open func addAction(_ action: UIAlertAction) {
        actions.append(action)
    }

    fileprivate var alertControllerView: UIAlertControllerView?

    override public func loadView() {
        self.view = UIAlertControllerBackdrop()

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

        UIView.animate(
            withDuration: animated ? animationTime * 1.25 : 0.0,
            options: [.allowUserInteraction],
            animations: { self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5) }
        )

        self.alertControllerView?.center = CGPoint(
            x: round(self.view.bounds.midX),
            y: round(self.view.bounds.midY)
        )
    }

    override func makeViewDisappear(animated: Bool, completion: @escaping (Bool) -> Void) {
        UIView.animate(
            withDuration: animated ? animationTime : 0.0,
            options: [.allowUserInteraction],
            animations: { view.alpha = 0 },
            completion: completion
        )
    }
}
