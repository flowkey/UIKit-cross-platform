//
//  UIApplication.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation
import SDL

open class UIApplication {
    public static var shared: UIApplication! // set via UIApplicationMain(_:_:_:_:)

    open internal(set) var delegate: UIApplicationDelegate?

    #if os(Android)
    open var isIdleTimerDisabled = false {
        didSet {
            guard
                let activity = try? jni.call("getContext", on: getSDLView(), returningObjectType: "android.content.Context"),
                let window = try? jni.call("getWindow", on: activity, returningObjectType: "android.view.Window")
            else { return }

            let FLAG_KEEP_SCREEN_ON: JavaInt = 128
            try? jni.call(
                isIdleTimerDisabled ? "addFlags" : "clearFlags",
                on: window,
                arguments: [FLAG_KEEP_SCREEN_ON]
            )
        }
    }
    #else
    open var isIdleTimerDisabled = false
    #endif

    open func sendEvent(_ event: UIEvent) {
        event.allTouches?.forEach { touch in touch.window = keyWindow }
        keyWindow?.sendEvent(event)
    }

    open weak var keyWindow: UIWindow? {
        didSet { keyWindow?.frame = UIScreen.main.bounds }
    }

    /// Currently not implemented but could be useful for Android
    open var statusBarStyle = UIStatusBarStyle.`default`

    // Useful in future: ?
    // open var preferredContentSizeCategory: UIContentSizeCategory { get }

    public required init() {
        UIScreen.main = UIScreen()
        UIFont.loadSystemFonts()
    }

    deinit {
        UIScreen.main = nil
        UIFont.clearCachedFontFiles()
        DisplayLink.activeDisplayLinks.removeAll()
    }
}


import SDL
import SDL_gpu
import CoreFoundation

extension UIApplication {
    func handleSDLQuit() {
        delegate?.applicationWillTerminate(self)
        UIApplication.shared = nil
        #if os(Android)
        try? jni.call("removeCallbacks", on: getSDLView())
        #elseif os(macOS)
        exit(0)
        #endif
    }
}

public enum UIStatusBarStyle {
    case `default`, lightContent
}


#if os(Android)
import JNI

private let maxFrameRenderTimeInSeconds = 1.0 / 60.0

@_cdecl("Java_org_libsdl_app_SDLActivity_nativeProcessEventsAndRender")
public func nativeProcessEventsAndRender(env: UnsafeMutablePointer<JNIEnv>, view: JavaObject) {
    let frameTime = Timer()
    UIApplication.shared.handleEventsIfNeeded()
    UIScreen.main?.render(window: UIApplication.shared.keyWindow, atTime: frameTime)
    let remainingFrameTime = maxFrameRenderTimeInSeconds - frameTime.elapsedTimeInSeconds
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, max(0.001, remainingFrameTime / 2), true)
}
#endif
