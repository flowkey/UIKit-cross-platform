//
//  UIAlertAction.swift
//  UIKit
//
//  Created by Chris on 28.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum UIAlertActionStyle {
    case `default`
    case cancel
    case destructive
}

public class UIAlertAction {
    public var title: String?
    public var style: UIAlertActionStyle

    public init(title: String?, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)? = nil) {
        self.title = title
        self.style = style
    }
}
