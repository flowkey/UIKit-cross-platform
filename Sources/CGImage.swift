//
//  Texture.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import SDL_gpu
import Foundation

public class CGImage {
    /// Be careful using this pointer e.g. for another CGImage instance.
    /// You will have to manually adjust its pointee's reference count.
    var rawPointer: UnsafeMutablePointer<GPU_Image>

    /// Stores the compressed image `Data` this `CGImage` was inited with (if any).
    /// This allows us to recreate the image if our OpenGL Context gets killed (esp. relevant for Android)
    private let sourceData: Data?

    public let width: Int
    public let height: Int

    /**
     Initialize a `CGImage` by passing a reference to a `GPU_Image`, which is usually the result of SDL_gpu's `GPU_*Image*` creation functions. May be null.
     */
    internal init?(_ pointer: UnsafeMutablePointer<GPU_Image>?, sourceData: Data? = nil) {
        guard let pointer = pointer else {
            // We check for GPU errors on render, so clear any error that may have caused GPU_Image to be nil.
            // It's possible there are unrelated errors on the stack at this point, but we immediately catch and
            // handle any errors that interest us *when they occur*, so it's fine to clear unrelated ones here.
            UIScreen.main?.clearErrors()
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
        let dataCount = Int32(data.count)

        guard let gpuImagePtr = data.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<Int8>) -> UnsafeMutablePointer<GPU_Image>? in
            let rw = SDL_RWFromMem(ptr, dataCount)
            return GPU_LoadImage_RW(rw, true)
        }) else { return nil }

        self.init(gpuImagePtr, sourceData: data)
    }

    convenience init?(surface: UnsafeMutablePointer<SDLSurface>) {
        guard let pointer = GPU_CopyImageFromSurface(surface) else { return nil }
        self.init(pointer)
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

        return withoutActuallyEscaping(pngWritingFunc) { (closure) -> Data? in
            var data = Data()
            stbi_write_png_to_func(closure, &data, surface.pointee.w, surface.pointee.h, Int32(surface.pointee.format.pointee.BytesPerPixel), surface.pointee.pixels, surface.pointee.pitch)
            return data.count > 0 ? data : nil
        }
    }
}
