#if canImport(Crlottie)
import Crlottie
internal import SDL_gpu

/// Wraps a single parsed Lottie animation (rlottie's `Lottie_Animation_S`).
public final class RLottieAnimation {
    fileprivate let handle: OpaquePointer
    public let size: CGSize
    public let frameRate: Double
    public let totalFrames: Int

    private init(handle: OpaquePointer) {
        self.handle = handle
        var w: Int = 0
        var h: Int = 0
        lottie_animation_get_size(handle, &w, &h)
        self.size = CGSize(width: CGFloat(w), height: CGFloat(h))
        self.frameRate = lottie_animation_get_framerate(handle)
        self.totalFrames = Int(lottie_animation_get_totalframe(handle))
    }

    deinit {
        lottie_animation_destroy(handle)
    }

    /// Mirrors the lottie-ios entry point: load `<name>.json` from a bundle.
    /// (No default for `bundle` because UIKit-cross-platform's Android `Bundle` has no `.main`.)
    public static func named(_ name: String, bundle: Bundle) -> RLottieAnimation? {
        guard let path = bundle.path(forResource: name, ofType: "json") else { return nil }
        guard let bytes = Data._fromPathCrossPlatform(path) else { return nil }
        let json = String(decoding: bytes, as: UTF8.self)

        // rlottie's `resource_path` is the directory it uses to resolve external image
        // assets referenced by the Lottie JSON. Pure-vector animations ignore it.
        var resourceDir = path
        if let slash = resourceDir.lastIndex(of: "/") {
            resourceDir.removeSubrange(slash..<resourceDir.endIndex)
        }

        return json.withCString { (jsonCStr) -> RLottieAnimation? in
            name.withCString { (keyCStr) -> RLottieAnimation? in
                resourceDir.withCString { (resourceDirCStr) -> RLottieAnimation? in
                    guard let h = lottie_animation_from_data(jsonCStr, keyCStr, resourceDirCStr) else {
                        return nil
                    }
                    return RLottieAnimation(handle: h)
                }
            }
        }
    }
}

public enum RLottieLoopMode: Equatable {
    case playOnce
    case loop
    case `repeat`(Float)
}

/// `UIView` that renders an `RLottieAnimation` frame-by-frame into its `layer.contents`.
/// Designed as a near drop-in for lottie-ios's `LottieAnimationView`.
public final class RLottieAnimationView: UIView {
    public var animation: RLottieAnimation? {
        didSet {
            guard animation !== oldValue else { return }
            resetRenderingState()
            if animation != nil { setNeedsLayout() }
        }
    }

    public var loopMode: RLottieLoopMode = .playOnce
    public var animationSpeed: CGFloat = 1.0

    public var contentMode: UIContentMode = .scaleAspectFit {
        didSet {
            switch contentMode {
            case .scaleToFill:        layer.contentsGravity = .resize
            case .scaleAspectFill:    layer.contentsGravity = .resizeAspectFill
            case .scaleAspectFit:     layer.contentsGravity = .resizeAspect
            case .center:             layer.contentsGravity = .center
            default:
                assertionFailure("contentMode \(contentMode) not implemented for RLottieAnimationView")
            }
        }
    }

    private let displayLink = DisplayLink()
    private var startTimer: Timer?
    private var completedLoops: Float = 0
    private var completion: ((Bool) -> Void)?

    private var renderBufferSize = (width: 0, height: 0)
    private var pixelBuffer: UnsafeMutablePointer<UInt32>?
    private var renderImage: CGImage?
    private var lastRenderedFrameIndex: Int = -1

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.contentsGravity = .resizeAspect
        displayLink.callback = { [weak self] in self?.tick() }
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    deinit {
        pixelBuffer?.deallocate()
    }

    public func play(completion: ((Bool) -> Void)? = nil) {
        guard animation != nil else {
            completion?(false)
            return
        }
        // Cancel previous completion (mirrors lottie-ios: replaying interrupts the prior call).
        self.completion?(false)
        self.completion = completion
        startTimer = Timer()
        completedLoops = 0
        displayLink.isPaused = false
    }

    public func stop() {
        displayLink.isPaused = true
        startTimer = nil
        completedLoops = 0
        let pending = completion
        completion = nil
        pending?(false)
    }

    private func resetRenderingState() {
        stop()
        renderImage = nil
        layer.contents = nil
        pixelBuffer?.deallocate()
        pixelBuffer = nil
        renderBufferSize = (0, 0)
        lastRenderedFrameIndex = -1
    }

    private func tick() {
        guard let animation, let startTimer else { return }
        let elapsed = startTimer.elapsedTimeInSeconds * max(0.0, Double(animationSpeed))
        let loopDurationSeconds = Double(animation.totalFrames) / max(1.0, animation.frameRate)

        let currentLoop = Float((elapsed / loopDurationSeconds).rounded(.down))
        if currentLoop > completedLoops {
            completedLoops = currentLoop
            switch loopMode {
            case .playOnce:
                renderFrame(animation, frameIndex: animation.totalFrames - 1)
                finishPlayback(success: true)
                return
            case .loop:
                break
            case .repeat(let max):
                if completedLoops >= max {
                    renderFrame(animation, frameIndex: animation.totalFrames - 1)
                    finishPlayback(success: true)
                    return
                }
            }
        }

        let positionInLoop = elapsed.truncatingRemainder(dividingBy: loopDurationSeconds)
        let frameIndex = min(
            animation.totalFrames - 1,
            Int((positionInLoop * animation.frameRate).rounded(.down))
        )
        renderFrame(animation, frameIndex: frameIndex)
    }

    private func finishPlayback(success: Bool) {
        displayLink.isPaused = true
        let pending = completion
        completion = nil
        pending?(success)
    }

    private func renderFrame(_ animation: RLottieAnimation, frameIndex: Int) {
        let scale = max(1, layer.contentsScale)
        let pixelWidth = max(1, Int((bounds.size.width * scale).rounded()))
        let pixelHeight = max(1, Int((bounds.size.height * scale).rounded()))

        let sizeChanged = pixelBuffer == nil
            || renderBufferSize.width != pixelWidth
            || renderBufferSize.height != pixelHeight

        if sizeChanged {
            pixelBuffer?.deallocate()
            pixelBuffer = UnsafeMutablePointer<UInt32>.allocate(capacity: pixelWidth * pixelHeight)
            renderBufferSize = (pixelWidth, pixelHeight)
            // GLES on Android only supports RGBA reliably — BGRA fails silently inside SDL_gpu
            // and trips the blit assertion on the next render. We swizzle in software below.
            renderImage = CGImage(width: pixelWidth, height: pixelHeight, format: GPU_FORMAT_RGBA)
            layer.contents = renderImage
            layer.contentsScale = scale
            lastRenderedFrameIndex = -1
        } else if frameIndex == lastRenderedFrameIndex {
            return
        }

        guard let buffer = pixelBuffer, let image = renderImage else { return }

        lottie_animation_render(
            animation.handle,
            frameIndex,
            buffer,
            pixelWidth,
            pixelHeight,
            pixelWidth * MemoryLayout<UInt32>.size
        )

        // rlottie writes ARGB (uint32). On little-endian that's stored as B,G,R,A bytes per
        // pixel; GPU_FORMAT_RGBA expects R,G,B,A.
        let pixelCount = pixelWidth * pixelHeight
        for i in 0..<pixelCount {
            let p = buffer[i]
            let b = p & 0xFF
            let r = (p >> 16) & 0xFF
            buffer[i] = (p & 0xFF00FF00) | (b << 16) | r
        }

        buffer.withMemoryRebound(to: UInt8.self, capacity: pixelCount * 4) { bytes in
            image.replacePixels(with: bytes, bytesPerPixel: 4)
        }
        lastRenderedFrameIndex = frameIndex
    }
}

#if os(Android)
// Android lacks lottie-ios. Expose the rlottie wrappers under the lottie-ios names so
// FlowkeyPlayer call-sites resolve to lottie-ios on iOS/Mac and to RLottie* on Android.
// On Mac, FlowkeyPlayer still imports lottie-ios directly — adding typealiases here would
// collide with the lottie-ios symbols of the same name.
public typealias LottieAnimation = RLottieAnimation
public typealias LottieAnimationView = RLottieAnimationView
public typealias LottieLoopMode = RLottieLoopMode
#endif

#endif // canImport(Crlottie)
