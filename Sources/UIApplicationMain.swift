//
//  UIApplication.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation

@discardableResult
public func UIApplicationMain(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>!, _ principalClassName: String?, _ delegateClassName: String?) -> Int32 {
    let applicationClass: UIApplication.Type? = classFromString(principalClassName)
    let delegateClass: UIApplicationDelegate.Type? = classFromString(delegateClassName)

    #if os(macOS)
    defer { setupRenderAndRunLoop() }
    #endif

    return UIApplicationMain(applicationClass, delegateClass)
}

private func classFromString<T>(_ string: String?) -> T? {
    guard let string = string else { return nil }
    return NSClassFromString(string) as? T
}

@discardableResult
internal func UIApplicationMain(
    _ applicationClass: UIApplication.Type?,
    _ applicationDelegateClass: UIApplicationDelegate.Type?) -> Int32
{
    UIApplication.shared = (applicationClass ?? UIApplication.self).init()

    guard let appDelegate = applicationDelegateClass?.init() else {
        // There was no app delegate specified, just make a default window and return
        let window = UIWindow(frame: CGRect(origin: .zero, size: UIScreen.main.bounds.size))
        window.rootViewController = UIViewController(nibName: nil, bundle: nil)
        window.makeKeyAndVisible()
        UIApplication.shared.keyWindow = window
        return 0
    }

    UIApplication.shared.delegate = appDelegate
    if !appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil) {
        // on iOS I think this prevents launching the app?
        assertionFailure("Returned false from AppDelegate, stopping launch")
        return 1
    }

    return 0
}

extension UIApplication {
    static func restart() {
        let applicationType = type(of: UIApplication.shared!)
        let delegateType = UIApplication.shared.delegate == nil ? nil : type(of: UIApplication.shared.delegate!).self

        UIApplication.shared.keyWindow = nil
        UIApplication.shared = nil

        DispatchQueue.main.async {
            UIApplicationMain(applicationType, delegateType)
        }
    }
}
