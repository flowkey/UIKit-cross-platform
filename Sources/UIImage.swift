//
//  UIImage+SDL.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 10.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL
import SDL_gpu
import Foundation

public class UIImage {
    public let cgImage: CGImage
    public let size: CGSize
    public let scale: CGFloat

    public init(cgImage: CGImage, scale: CGFloat) {
        self.cgImage = cgImage
        self.scale = scale
        self.size = CGSize(
            width: CGFloat(cgImage.width),
            height: CGFloat(cgImage.height)
        )
    }

    public convenience init?(named name: String) {
        let (pathWithoutExtension, fileExtension) = name.pathAndExtension()
        let possibleFileExtensions = ["", ".\(fileExtension)", ".png", ".jpg", ".jpeg", ".bmp"]

        // e.g. ["@3x", "@2x", "@1x", ""]
        let scale = Int(UIScreen.main.scale.rounded())
        let possibleScaleStrings = stride(from: scale, through: 1, by: -1)
            .map { "@\($0)x" }
            + [""] // it's possible to have no scale string (e.g. "image.png")

        for ext in possibleFileExtensions {
            for scaleString in possibleScaleStrings {
                let attemptedFilePath = "\(pathWithoutExtension)\(scaleString)\(ext)"
                if let cgImage = CGImage(GPU_LoadImage(attemptedFilePath)) {
                    let scale = attemptedFilePath.extractImageScale()
                    self.init(cgImage: cgImage, scale: scale)
                    return
                }
            }
        }

        return nil
    }

    public convenience init?(path: String) {
        guard let cgImage = CGImage(GPU_LoadImage(path)) else { return nil }
        self.init(cgImage: cgImage, scale: path.extractImageScale())
    }

    public convenience init?(data: Data) {
        var data = data
        let dataCount = Int32(data.count)
        let gpuImagePtr = data.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<Int8>) -> UnsafeMutablePointer<GPU_Image>? in
            let rw = SDL_RWFromMem(ptr, dataCount)
            defer { SDL_FreeRW(rw) }
            return GPU_LoadImage_RW(rw, false)
        }

        guard let cgImage = CGImage(gpuImagePtr) else { return nil }
        self.init(cgImage: cgImage, scale: 1.0) // matches iOS
    }
}

private extension String {
    /**
     Get the absolute path of the current string (if needed / possible on this platform), and split the file extension from it (if one is present).

     Returns:
     - the path without its extension
     - the extension itself (or `nil` if none was present)
     **/
    func pathAndExtension() -> (pathWithoutExtension: String, fileExtension: String) {
        let path = self.asAbsolutePath() as NSString
        return (path.deletingPathExtension, path.pathExtension)
    }

    func extractImageScale() -> CGFloat {
        let pathWithoutExtension = (self as NSString).deletingPathExtension

        if pathWithoutExtension.hasSuffix("@3x") {
            return 3.0
        } else if pathWithoutExtension.hasSuffix("@2x") {
            return 2.0
        }

        return 1.0
    }

    private func asAbsolutePath() -> String {
        #if os(macOS)
        if !self.hasPrefix("/") {
            return Bundle(for: UIImage.self).path(forResource: self, ofType: nil) ?? self
        }
        // Mac can fall through to the following code if we already have an absolute path:
        #endif
        // Android doesn't need absolute paths:
        return self
    }
}
