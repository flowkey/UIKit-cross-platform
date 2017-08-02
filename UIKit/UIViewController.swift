//
//  UIViewController.swift
//  UIKit
//
//  Created by Chris on 01.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIViewController {
    open func present(_ controllerToPresent: UIAlertController, animated: Bool, completion: (() -> Void)?) {
        print("Title:", controllerToPresent.title)
        print("Message:", controllerToPresent.message)
    }
}
