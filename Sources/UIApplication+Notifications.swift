//
//  UIApplication+Notifications.swift
//  UIKit
//
//  Created by Chetan Agarwal on 30.11.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

extension UIApplication {
    public class var didEnterBackgroundNotification: Notification.Name {
        return Notification.Name.UIApplicationDidEnterBackground
    }

    public class var willEnterForegroundNotification: Notification.Name {
        return Notification.Name.UIApplicationWillEnterForeground
    }

    public class var didBecomeActiveNotification: Notification.Name {
        return Notification.Name.UIApplicationDidBecomeActive
    }

    public class var willResignActiveNotification: Notification.Name {
        return Notification.Name.UIApplicationWillResignActive
    }
}

extension Notification.Name {
    public static let UIApplicationDidEnterBackground
        = Notification.Name(rawValue: "UIApplicationDidEnterBackgroundNotification")

    public static let UIApplicationWillEnterForeground
        = Notification.Name(rawValue: "UIApplicationWillEnterForegroundNotification")

    public static let UIApplicationDidBecomeActive
        = Notification.Name(rawValue: "UIApplicationDidBecomeActiveNotification")

    public static let UIApplicationWillResignActive
        = Notification.Name(rawValue: "UIApplicationWillResignActiveNotification")
}
