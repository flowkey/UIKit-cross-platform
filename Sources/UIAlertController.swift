//
//  UIAlertController.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum UIAlertControllerStyle {
    case actionSheet
    case alert
}

public class UIAlertController {
    public var title: String?
    public var message: String?
    public var preferredStyle: UIAlertControllerStyle

    public var actions: [UIAlertAction]

    public init(title: String?, message: String?, preferredStyle: UIAlertControllerStyle) {
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        self.actions = []
    }

    public func addAction(_ action: UIAlertAction) {
        actions.append(action)
    }
}
