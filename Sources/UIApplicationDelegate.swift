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

    // Note: this is not used on Android, because there we have a library, so no `main` function will be called.
    @MainActor
    static func main() async throws {
        #if os(macOS)
        // On Mac (like on iOS), the main thread blocks here via RunLoop.current.run().
        defer { setupRenderAndRunLoop() }
        #else
        // Android is handled differently: we don't want to block the main thread because the system needs it.
        // Instead, we call render periodically from Kotlin via the Android Choreographer API (see UIApplication).
        // That said, this function won't even be called on platforms like Android where the app is built as a library, not an executable.
        #endif

        _ = UIApplicationMain(UIApplication.self, Self.self)
    }
}
