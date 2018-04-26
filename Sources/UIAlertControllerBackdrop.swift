//
//  UIAlertControllerBackdrop.swift
//  UIKit
//
//  Created by Geordie Jay on 26.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

class UIAlertControllerBackdrop: UIView {
    convenience init() {
        self.init(frame: .zero)

        // Default is `nil`, meaning we couldn't animate this otherwise:
        backgroundColor = .clear
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        (self.next as? UIAlertController)?.dismiss(animated: true)
    }
}
