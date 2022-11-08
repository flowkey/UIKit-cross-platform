//
//  UIApplicationDelegate.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import func Foundation.NSStringFromClass

public extension UIApplication {
    struct LaunchOptionsKey: RawRepresentable, Hashable {
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

public protocol UIApplicationDelegate: AnyObject {
    init()
    var window: UIWindow? { get set }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    func applicationWillTerminate(_ application: UIApplication)

    func applicationWillEnterForeground(_ application: UIApplication)
    func applicationDidBecomeActive(_ application: UIApplication)

    func applicationWillResignActive(_ application: UIApplication)
    func applicationDidEnterBackground(_ application: UIApplication)
}

// Swift doesn't have optional protocol requirements like objc does, so provide defaults:
public extension UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    
    @MainActor
    static func main() {
        var argv: UnsafeMutablePointer<Int8>? = nil
        _ = UIApplicationMain(0, &argv, nil, NSStringFromClass(Self.self))
    } 
}
