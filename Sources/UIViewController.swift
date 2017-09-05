//
//  UIViewController.swift
//  UIKit
//
//  Created by Chris on 01.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIViewController {
    open func present(_ presentedController: UIAlertController, animated: Bool, completion: (() -> Void)?) {
        print("About to present UIViewController (not yet implemented):")
        print("Title:", presentedController.title ?? "(none)")
        print("Message:", presentedController.message ?? "(none)")
    }
}
