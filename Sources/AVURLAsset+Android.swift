#if os(Android)
import JNI

public class AVPlayerItem {
    public var asset: AVURLAsset
    public init(asset: AVURLAsset) {
        self.asset = asset
    }
}

public final class AVURLAsset: JNIObject {
    public override static var className: String { "org.uikit.AVURLAsset" }

    @MainActor
    public var url: String?

    @MainActor
    convenience public init(url: String) {
        try! self.init(arguments: JavaSDLView(getSDLView()), url)
        self.url = url
    }
}
#endif
