//
//  Button.swift
//  UIKitTests
//
//  Created by Chris on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import UIKit

public class Button: UIButton {
    var image: UIImage? {
        didSet {
            setImage(image, for: .normal)
            setImage(image, for: .highlighted)
        }
    }

    public var onPress: (() -> Void)? {
        didSet {
            if onPress != nil {
                // The docs say it is safe to add the same target/action multiple times:
                addTarget(self, action: #selector(handleOnPress), for: .touchUpInside)
            } else {
                removeTarget(self, action: #selector(handleOnPress), for: .touchUpInside)
            }
        }
    }

    @objc private func handleOnPress() {
        onPress?()
    }
}
