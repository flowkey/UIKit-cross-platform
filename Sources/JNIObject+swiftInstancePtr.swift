#if os(Android)
import JNI

extension JNIObject {
    /// An opaque pointer to `self`, passed to the Java side so native callbacks can
    /// resolve back to this instance. Shared by AVPlayer and AVAudioPlayer.
    var swiftInstancePtr: JavaLong {
        let ptr = Unmanaged.passUnretained(self).toOpaque()
        return JavaLong(Int(bitPattern: ptr))
    }
}
#endif
