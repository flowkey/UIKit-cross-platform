import SDL

// This function doesn't exist in the actual UIKit of course,
// but the app entrypoint is easily customizable, so it doesn't
// really matter whether this is identical across platforms.

@discardableResult
public func UIApplicationMain(
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
