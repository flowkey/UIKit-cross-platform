import JNI
import UIKit

@_silgen_name("JNI_OnLoad")
public func JNI_OnLoad(jvm: UnsafeMutablePointer<JavaVM>, reserved: UnsafeMutableRawPointer) -> JavaInt {
    UIKitAndroid.UIApplicationDelegateClass = AppDelegate.self

    return JNI_VERSION_1_6
}

@_silgen_name("Java_com_example_MainActivity_callSwiftFromKotlin")
public func callSwiftFromKotlin(env: UnsafeMutablePointer<JNIEnv>, instance: JavaObject, message: JavaString) {
    print("Message from Kotlin: " + (try! String(javaString: message)))
}
