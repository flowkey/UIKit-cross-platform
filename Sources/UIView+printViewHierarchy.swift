//
//  UIView+printViewHierarchy.swift
//  UIKit
//
//  Created by Geordie Jay on 20.03.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

extension UIView {
    func printViewHierarchy(depth: Int = 0) {
        if self.isHidden || self.alpha < 0.01 { return }
        let indentation = (0 ..< depth).reduce("") { result, _ in result + "  " }
        print(indentation + "✳️ " + self.description.replacing("\n", with: "\n" + indentation))

        let newDepth = depth + 1
        for subview in subviews {
            subview.printViewHierarchy(depth: newDepth)
        }
    }
}
