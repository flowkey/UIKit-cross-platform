//
//  UIApplication.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL
import func Foundation.NSClassFromString

@MainActor
@discardableResult
public func UIApplicationMain(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>, _ principalClassName: String?, _ delegateClassName: String?) -> Int32 {
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

@MainActor
@discardableResult
internal func UIApplicationMain(
    _ applicationClass: UIApplication.Type?,
    _ applicationDelegateClass: UIApplicationDelegate.Type?) -> Int32
{
    let application = (applicationClass ?? UIApplication.self).init()
    UIApplication.shared = application

    guard let appDelegate = applicationDelegateClass?.init() else {
        // iOS doesn't create a window by default either
        // What it does do is load the main storyboard if one is specified, but we can't do that (yet?)
        assertionFailure(
            "There was no AppDelegate class specified. Please provide one using the last parameter of UIApplicationMain," +
            " e.g. `UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.self))`")
        return 1
    }

    application.delegate = appDelegate

    if appDelegate.application(application, didFinishLaunchingWithOptions: nil) == false {
        return 1
    }

    return 0
}
