
#if os(Android)
import JNI
#endif

extension UIWindow {
    static func getSafeAreaInsets() -> UIEdgeInsets {
        #if os(Android)
        let windowInsets: JavaObject = try! jni.call(
            "getSafeAreaInsets",
            on: getSDLView(),
            returningObjectType: "android.graphics.RectF"
        )
        let top: JavaFloat = try! jni.GetField("top", from: windowInsets)
        let left: JavaFloat = try! jni.GetField("left", from: windowInsets)
        let bottom: JavaFloat = try! jni.GetField("bottom", from: windowInsets)
        let right: JavaFloat = try! jni.GetField("right", from: windowInsets)

        return UIEdgeInsets(
            top: CGFloat(top),
            left: CGFloat(left),
            bottom: CGFloat(bottom),
            right: CGFloat(right)
        )
        #else
        return .zero
        #endif
    }
}
