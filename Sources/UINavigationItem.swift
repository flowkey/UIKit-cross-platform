//
//  UINavigationItem.swift
//  UIKit
//
//  Created by flowing erik on 19.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation

open class UINavigationItem {
    public func setRightBarButton(_ item: UIBarButtonItem?, animated: Bool) {

    }

}


open class UIBarButtonItem : UIBarItem/*, NSCoding*/ {
    public init (barButtonSystemItem: UIBarButtonSystemItem, action: () -> Void) {

    }
}

open class UIBarItem/* : NSObject, NSCoding, UIAppearance*/ {

}

public enum UIBarButtonSystemItem {
    case done
    // TODO: add others
}

