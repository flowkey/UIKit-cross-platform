//
//  UINavigationController.swift
//  UIKit
//
//  Created by flowing erik on 19.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation


open class UINavigationController: UIViewController {

    public var navigationBar = UINavigationBar()
    
    public init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
    }
}


open class UINavigationBar: UIView {

}
