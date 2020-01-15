## Prepare your iOS Project

1. Delete `Main.storyboard` and remove its reference from `Info.plist`
2. Remove the entire block `Application Scene Manifest` from `Info.plist` and delete the file `SceneDelegate.swift`.
3. Modify `AppDelegate.swift`:

-   Remove the `@UIApplicationMain` attribute and make the `AppDelegate` class `final`
-   Initialize `UIWindow` and your initial `ViewController` in the `application` function
-   Remove application delegates related to `UIScene` and `UISceneSession`

```swift
// AppDelegate.swift

// @UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow()
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()

        return true
    }
}
```

3. Create a `main.swift` file:

```swift
// main.swift

import UIKit
import Foundation

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
```
