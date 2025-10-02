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
    static func main() async throws {
        #if !os(Android) // Unused on Android: we build a library, so no `main` function gets called.
        _ = UIApplicationMain(UIApplication.self, Self.self)

        // On Mac (like on iOS), the main thread blocks here via RunLoop.current.run().
        setupRenderAndRunLoop()
        #endif // !os(Android)
    }
}
