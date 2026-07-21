#if os(Android)
import JNI

public protocol AVAudioPlayerDelegate: AnyObject {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
}

public final class AVAudioPlayer: JNIObject {
    public override static var className: String { "org.uikit.AVAudioPlayer" }

    public weak var delegate: AVAudioPlayerDelegate?

    public var volume: Float = 1.0 {
        didSet { try? call("setVolume", arguments: [Double(volume)]) }
    }

    @MainActor
    public convenience init(assetPath: String) throws {
        try self.init(arguments: JavaSDLView(getSDLView()), assetPath)
        try? call("setSwiftInstancePtr", arguments: [swiftInstancePtr])
    }

    public var deviceCurrentTime: Double {
        return (try? call("getDeviceCurrentTime")) ?? 0
    }

    @discardableResult
    public func prepareToPlay() -> Bool {
        return (try? call("prepareToPlay")) ?? false
    }

    @discardableResult
    public func play(atTime time: Double) -> Bool {
        try? call("playAtTime", arguments: [time])
        return true
    }

    deinit {
        try? call("cleanup")
    }
}

@_cdecl("Java_org_uikit_AVAudioPlayer_nativeOnCompletion")
public func nativeOnAudioPlayerCompletion(
    env: UnsafeMutablePointer<JNIEnv>,
    cls: JavaObject,
    swiftInstancePtr: JavaLong,
    success: JavaBoolean
) {
    guard let player = AVAudioPlayer.from(swiftInstancePtr: swiftInstancePtr) else { return }
    player.delegate?.audioPlayerDidFinishPlaying(player, successfully: success != 0)
}

extension AVAudioPlayer {
    static func from(swiftInstancePtr: JavaLong) -> AVAudioPlayer? {
        guard let reference = UnsafeRawPointer(bitPattern: Int(swiftInstancePtr)) else { return nil }
        return Unmanaged<AVAudioPlayer>.fromOpaque(reference).takeUnretainedValue()
    }
}
#endif
