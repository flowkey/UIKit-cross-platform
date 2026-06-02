//
//  Data+fromRelativePathCrossPlatform.swift
//  UIKit
//
//  Created by Geordie Jay on 01.11.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

internal import SDL

extension Data {
    /// Reads a file via SDL_RWops. On Android this dispatches to the platform
    /// AssetManager, so paths returned by `Bundle.path(forResource:ofType:)` resolve
    /// against the APK's `assets/` directory rather than the filesystem — which is
    /// why `Data(contentsOf:)` isn't a drop-in replacement here.
    public static func _fromPathCrossPlatform(_ path: String) -> Data? {
        guard let fileReader = SDL_RWFromFile(path, "r") else {
            return nil
        }

        defer { _ = fileReader.pointee.close(fileReader) }

        let fileSize = Int(fileReader.pointee.size(fileReader))

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: fileSize)
        defer { buffer.deallocate() }

        let bytesRead = fileReader.pointee.read(fileReader, buffer, 1, fileSize)
        if bytesRead == fileSize {
            return Data(UnsafeBufferPointer(start: buffer, count: fileSize))
        } else {
            return nil
        }
    }
}
