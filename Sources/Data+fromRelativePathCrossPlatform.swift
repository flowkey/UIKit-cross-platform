//
//  Data+fromRelativePathCrossPlatform.swift
//  UIKit
//
//  Created by Geordie Jay on 01.11.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

extension Data {
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
