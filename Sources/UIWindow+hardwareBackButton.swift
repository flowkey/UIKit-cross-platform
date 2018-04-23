//
//  UIWindow+hardwareBackButton.swift
//  UIKitTests
//
//  Created by Geordie Jay on 23.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

internal extension UIWindow {
    func deepestPresentedView() -> UIView {
        // We use the presented view controllers to catch pop-over views etc
        // that are not necessarily visible at the centre of the window.
        let deepestViewControllerView = (rootViewController?.deepestPresentedViewController.view) ?? self
        return deepestViewControllerView.deepestVisibleViewAtCenter()
    }
}

private extension UIView {
    func deepestVisibleViewAtCenter() -> UIView {
        return hitTest(CGPoint(x: bounds.midX, y: bounds.midY), with: nil) ?? self
    }
}

private extension UIViewController {
    var deepestPresentedViewController: UIViewController {
        var deepestViewController = self
        while let newDeepest = deepestViewController.presentedViewController {
            deepestViewController = newDeepest
        }
        return deepestViewController
    }
}
