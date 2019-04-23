//
//  UIActivityIndicatorView.swift
//  UIKit
//
//  Created by Chris on 09.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum UIActivityIndicatorViewStyle {
    case whiteLarge
    case white
    case gray
}

public class UIActivityIndicatorView: UIView {
    public var activityIndicatorStyle: UIActivityIndicatorViewStyle

    public init(style: UIActivityIndicatorViewStyle) {
        self.activityIndicatorStyle = style
        super.init(frame: .zero)
    }

    public func startAnimating() {

    }
    public func stopAnimating() {

    }
}
