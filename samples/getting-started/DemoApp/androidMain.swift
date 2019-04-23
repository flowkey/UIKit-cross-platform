import JNI
import UIKit

@_cdecl("JNI_OnLoad")
public func JNI_OnLoad(jvm: UnsafeMutablePointer<JavaVM>, reserved: UnsafeMutableRawPointer) -> JavaInt {
    UIKitAndroid.UIApplicationDelegateClass = AppDelegate.self

    return JNI_VERSION_1_6
}
