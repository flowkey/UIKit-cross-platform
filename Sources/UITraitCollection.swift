//
//  UITraitCollection.swift
//  UIKit
//
//  Copyright © 2026 flowkey. All rights reserved.
//

public enum UIUserInterfaceSizeClass: Int, Sendable {
    case unspecified = 0
    case compact = 1
    case regular = 2
}

public struct UITraitCollection: Equatable, Sendable {
    public let horizontalSizeClass: UIUserInterfaceSizeClass
    public let verticalSizeClass: UIUserInterfaceSizeClass

    /// Android's window size class breakpoints: compact below 600 points wide or 480 points tall.
    /// https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes
    init(windowSize: CGSize) {
        horizontalSizeClass = windowSize.width >= 600 ? .regular : .compact
        verticalSizeClass = windowSize.height >= 480 ? .regular : .compact
    }
}

extension UIView {
    public var traitCollection: UITraitCollection {
        var rootView = self
        while let superview = rootView.superview { rootView = superview }
        let windowSize = rootView is UIWindow ? rootView.bounds.size : UIScreen.main?.bounds.size ?? .zero
        return UITraitCollection(windowSize: windowSize)
    }
}

extension UIViewController {
    public var traitCollection: UITraitCollection {
        view.traitCollection
    }
}
