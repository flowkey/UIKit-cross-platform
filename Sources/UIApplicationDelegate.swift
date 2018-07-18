//
//  UIApplicationDelegate.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

/// Not currently implemented for crossplatform UIKit
public enum UIApplicationLaunchOptionsKey: String {
    case dummy
}


public protocol UIApplicationDelegate: class {
    init()
    var window: UIWindow? { get set } // Not sure what's supposed to happen when you set this

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    func applicationWillTerminate(_ application: UIApplication)

    // NOTE: THE FOLLOWING ARE NOT YET IMPLEMENTED!
    func applicationDidEnterBackground(_ application: UIApplication)
    func applicationWillEnterForeground(_ application: UIApplication)

    func applicationDidBecomeActive(_ application: UIApplication)
    func applicationWillResignActive(_ application: UIApplication)
}

// Swift doesn't have optional protocol requirements like objc does, so provide defaults:
public extension UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillResignActive(_ application: UIApplication) {}
}
