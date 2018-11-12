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

    /// As on iOS: if no file extension is provided, assume `.png`.
    public convenience init?(named name: String) {
        let (pathWithoutExtension, fileExtension) = name.pathAndExtension()

        // e.g. ["@3x", "@2x", ""]
        let scale = Int(UIScreen.main.scale.rounded())
        let possibleScaleStrings = stride(from: scale, to: 1, by: -1)
            .map { "@\($0)x" }
            + [""] // it's possible to have no scale string (e.g. "image.png")

        for scaleString in possibleScaleStrings {
            let attemptedFilePath = "\(pathWithoutExtension)\(scaleString)\(fileExtension)"
            if let data = Data.fromPathCrossPlatform(attemptedFilePath) {
                self.init(data: data, scale: attemptedFilePath.extractImageScale())
                return
            }
        }

        print("Couldn't find image named", name)

        return nil
    }

    public convenience init?(path: String) {
        guard let data = Data.fromPathCrossPlatform(path) else { return nil }
        self.init(data: data, scale: path.extractImageScale())
    }

    public convenience init?(data: Data) {
        self.init(data: data, scale: 1.0) // matches iOS
    }

    private convenience init?(data: Data, scale: CGFloat) {
        guard let cgImage = CGImage(data) else {
            return nil
        }

        self.init(cgImage: cgImage, scale: scale)
    }
}

private extension String {
    func pathAndExtension() -> (pathWithoutExtension: String, fileExtension: String) {
        let path = NSString(string: self.asAbsolutePath())
        let fileExtension = path.pathExtension
        return (path.deletingPathExtension, "." + (fileExtension.isEmpty ? "png" : fileExtension))
    }

    func extractImageScale() -> CGFloat {
        let pathWithoutExtension = NSString(string: self).deletingPathExtension

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
