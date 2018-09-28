//
//  UIApplication.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation
import SDL

@discardableResult
public func UIApplicationMain(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>!, _ principalClassName: String?, _ delegateClassName: String?) -> Int32 {
    let applicationClass: UIApplication.Type? = classFromString(principalClassName)
    let delegateClass: UIApplicationDelegate.Type? = classFromString(delegateClassName)

    #if os(macOS)
    // On Mac (like on iOS), the main thread blocks here via RunLoop.current.run().
    defer { setupRenderAndRunLoop() }
    #else
    // Android is handled differently: we don't want to block the main thread because the system needs it.
    // Instead, we call render periodically from Kotlin via the Android Choreographer API (see UIApplication)
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
        // iOS doesn't create a window by default either
        // What it does do is load the main storyboard if one is specified, but we can't do that (yet?)
        assertionFailure(
            "There was no AppDelegate class specified. Please provide one using the last parameter of UIApplicationMain," +
            " e.g. `UIApplicationMain(0, nil, nil, NSStringFromClass(AppDelegate.self))`")
        return 1
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
    static func restart(_ onRestarted: (() -> Void)? = nil) {
        guard UIApplication.shared != nil else {
            print("Tried to restart but no application was running")
            return
        }

        let applicationType = type(of: UIApplication.shared!)
        let delegateType = UIApplication.shared!.delegate != nil ? type(of: UIApplication.shared!.delegate!).self : nil

        UIApplication.shared = nil

        DispatchQueue.main.async {
            // Wrap this in another async block because UIApplicationMain is blocking on Mac:
            DispatchQueue.main.async { onRestarted?() }
            UIApplicationMain(applicationType, delegateType)
        }
    }
}
