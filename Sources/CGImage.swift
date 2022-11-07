import SDL
import SDL_gpu
import struct Foundation.Data

public class CGImage {
    /// Be careful using this pointer e.g. for another CGImage instance.
    /// You will have to manually adjust its pointee's reference count.
    var rawPointer: UnsafeMutablePointer<GPU_Image> {
        didSet { Task { @MainActor in CALayer.layerTreeIsDirty = true } }
    }

    /// Stores the compressed image `Data` this `CGImage` was inited with (if any).
    /// This allows us to recreate the image if our OpenGL Context gets killed (esp. relevant for Android)
    private let sourceData: Data?

    public let width: Int
    public let height: Int

    /**
     Initialize a `CGImage` by passing a reference to a `GPU_Image`, which is usually the result of SDL_gpu's `GPU_*Image*` creation functions. May be null.
     The second parameter provides the compressed image source data (in PNG, JPG etc. format). The source data will be used to recreate the `GPU_Image` if the GLContext has been invalidated (which happens quite commonly on Android). Not providing source data means you will have to recreate the `CGImage` yourself if it fails to render, usually by overriding your `CALayer`'s display() method.
     */
    internal init?(_ pointer: UnsafeMutablePointer<GPU_Image>?, sourceData: Data?) {
        guard let pointer = pointer else {
            // We check for GPU errors on render, so clear any error that may have caused GPU_Image to be nil.
            // It's possible there are unrelated errors on the stack at this point, but we immediately catch and
            // handle any errors that interest us *when they occur*, so it's fine to clear unrelated ones here.
            Task { @MainActor in UIScreen.main?.clearErrors() }
            return nil
        }

        self.sourceData = sourceData
        rawPointer = pointer

        GPU_SetSnapMode(rawPointer, GPU_SNAP_POSITION_AND_DIMENSIONS)
        GPU_SetBlendMode(rawPointer, GPU_BLEND_NORMAL_FACTOR_ALPHA)
        GPU_SetImageFilter(rawPointer, GPU_FILTER_LINEAR)

        width = Int(rawPointer.pointee.w)
        height = Int(rawPointer.pointee.h)
    }

    internal convenience init?(_ sourceData: Data) {
        var data = sourceData

        guard let gpuImagePtr = data.withUnsafeMutableBytes({ buffer -> UnsafeMutablePointer<GPU_Image>? in
            guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: Int8.self) else {
                return nil
            }

            let rw = SDL_RWFromMem(ptr, Int32(buffer.count))
            return GPU_LoadImage_RW(rw, true)
        }) else { return nil }

        self.init(gpuImagePtr, sourceData: data)
    }

    convenience init?(surface: UnsafeMutablePointer<SDLSurface>) {
        guard let pointer = GPU_CopyImageFromSurface(surface) else { return nil }
        self.init(pointer, sourceData: nil)
    }

    internal func replacePixels(with bytes: UnsafePointer<UInt8>, bytesPerPixel: Int) {
        var rect = GPU_Rect(x: 0, y: 0, w: Float(rawPointer.pointee.w), h: Float(rawPointer.pointee.h))
        GPU_UpdateImageBytes(rawPointer, &rect, bytes, Int32(rawPointer.pointee.w) * Int32(bytesPerPixel))
    }

    /// Recreate the underlying `GPU_Image` (`self.rawPointer`) from this `CGImage`'s source data if possible.
    /// - Returns: `true`, if it was possible to recreate the image. Or `false`, if there was no underlying source data, or when SDL_gpu could not decode that data.
    internal func reloadFromSourceData() -> Bool {
        guard let sourceData = sourceData, let newImage = CGImage(sourceData) else {
            return false
        }

        // Free the old GPU_Image before replacing it (this may be our last chance)
        GPU_FreeImage(rawPointer)

        // If we don't increase the new image's refcount it will be deinited along
        // with the CGImageRef that goes out of scope at the end of this function.
        newImage.rawPointer.pointee.refcount += 1

        self.rawPointer = newImage.rawPointer

        return true
    }

    deinit {
        GPU_FreeImage(rawPointer)
    }

    public func pngData() -> Data? {
        guard let surface = GPU_CopySurfaceFromImage(rawPointer) else { return nil }
        defer { SDL_FreeSurface(surface) }

        let pngWritingFunc: @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, Int32) -> Void = { (outData, pngData, dataSize) in
            guard let pngData = pngData, dataSize > 0 else { return }
            outData?.assumingMemoryBound(to: Data.self)
                .pointee
                .append(pngData.assumingMemoryBound(to: UInt8.self), count: Int(dataSize))
        }

        var data = Data()
        stbi_write_png_to_func(pngWritingFunc, &data, surface.pointee.w, surface.pointee.h, Int32(surface.pointee.format.pointee.BytesPerPixel), surface.pointee.pixels, surface.pointee.pitch)
        return data.count > 0 ? data : nil
    }
}
