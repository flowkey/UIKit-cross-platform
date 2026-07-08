internal import SDL
import Dispatch

#if canImport(UIKit_C_API)
@_exported import UIKit_C_API
#endif

@MainActor
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
        MainActor.assumeIsolated {
            UIScreen.main = nil
            UIFont.clearCachedFontFiles()
            DisplayLink.activeDisplayLinks.removeAll()
        }
    }
}


internal import SDL
internal import SDL_gpu

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

// ******************
// Requires Dispatch
import Dispatch
@_silgen_name("_dispatch_main_queue_callback_4CF")
public func dispatchMainQueueCallback(_ msg: UnsafeMutableRawPointer?) -> Void
// ******************

@MainActor
@_cdecl("Java_org_libsdl_app_SDLActivity_nativeProcessEventsAndRender")
public func nativeProcessEventsAndRender(env: UnsafeMutablePointer<JNIEnv>?, view: JavaObject?) {
    let frameTime = Timer()
    UIApplication.shared?.handleEventsIfNeeded()
    UIScreen.main?.render(window: UIApplication.shared?.keyWindow, atTime: frameTime)

    // <Service the main queue / thread / actor>
    // Note: this would be more efficiently and effectively
    // served by the newer Swift executor APIs

    // Arbitrary, but designed to get "a lot" of work done if needed
    // without boosting baseline CPU usage noticeably above 0%:
    let N = 64

    for _ in 0 ..< N {
        // This loop is designed to ensure the main queue is serviced
        // thoroughly, especially on shutdown where the frame callback is no
        // longer called regularly but there might still be cleanup work to
        // do on the Main Actor e.g. upon deinit.
        dispatchMainQueueCallback(nil)
        if frameTime.elapsedTimeInMilliseconds > 8 {
            // Process the main queue at least once per frame, up to N times
            // provided that processing doesn't take us beyond 50% of the
            // frame budget @60fps.
            break
        }
    }

    // </Service the main queue / thread / actor>
}
#endif
