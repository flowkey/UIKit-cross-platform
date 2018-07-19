
## Prepare your iOS Project

1. Delete `Main.storyboard` and remove its reference from `Info.plist`

2. Modify `AppDelegate.swift`:
- Remove the `@UIApplicationMain` attribute and make the `AppDelegate` class `final`
- Initialize `UIWindow` and your initial `ViewController` in the `application` function
```swift
// AppDelegate.swift

// @UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow()
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()

        return true
    }
    ...
}
```

3. Create a `main.swift` file:
```swift
// main.swift

import UIKit
import Foundation

UIApplicationMain(0, nil, nil, NSStringFromClass(AppDelegate.self))
```

