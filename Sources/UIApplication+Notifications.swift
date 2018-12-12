//
//  UIApplication+Notifications.swift
//  UIKit
//
//  Created by Chetan Agarwal on 30.11.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

extension UIApplication {
    public class var didEnterBackgroundNotification: NSNotification.Name {
        return NSNotification.Name.UIApplicationDidEnterBackground
    }

    public class var willEnterForegroundNotification: NSNotification.Name {
        return NSNotification.Name.UIApplicationWillEnterForeground
    }

    public class var didBecomeActiveNotification: NSNotification.Name {
        return NSNotification.Name.UIApplicationDidBecomeActive
    }

    public class var willResignActiveNotification: NSNotification.Name {
        return NSNotification.Name.UIApplicationWillResignActive
    }
}

extension NSNotification.Name {
    public static let UIApplicationDidEnterBackground
        = NSNotification.Name(rawValue: "UIApplicationDidEnterBackgroundNotification")

    public static let UIApplicationWillEnterForeground
        = NSNotification.Name(rawValue: "UIApplicationWillEnterForegroundNotification")

    public static let UIApplicationDidBecomeActive
        = NSNotification.Name(rawValue: "UIApplicationDidBecomeActiveNotification")

    public static let UIApplicationWillResignActive
        = NSNotification.Name(rawValue: "UIApplicationWillResignActiveNotification")
}
