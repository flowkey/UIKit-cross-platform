import JNI
import UIKit

@_silgen_name("JNI_OnLoad")
public func JNI_OnLoad(jvm: UnsafeMutablePointer<JavaVM>, reserved: UnsafeMutableRawPointer) -> JavaInt {
    UIKitAndroid.UIApplicationDelegateClass = AppDelegate.self

    return JNI_VERSION_1_6
}
