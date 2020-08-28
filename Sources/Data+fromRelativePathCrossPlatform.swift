//
//  Data+fromRelativePathCrossPlatform.swift
//  UIKit
//
//  Created by Geordie Jay on 01.11.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation

extension Data {
    public static func _fromPathCrossPlatform(_ path: String) -> Data? {
        #if !os(Android)
        // At time of writing the SDL code below worked on all supported SDL platforms.
        // But, because of some crashes in `Data` we're doing an unneccessary copy there
        // which makes that version less efficient than Foundation's, so use it here instead:
        return try? Data(contentsOf: URL(fileURLWithPath: path))
        #else
        guard let fileReader = SDL_RWFromFile(path, "r") else {
            return nil
        }

        defer { _ = fileReader.pointee.close(fileReader) }

        let fileSize = Int(fileReader.pointee.size(fileReader))

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: fileSize)
        defer { buffer.deallocate() }

        let bytesRead = fileReader.pointee.read(fileReader, buffer, 1, fileSize)
        if bytesRead == fileSize {
            return Data(bytes: buffer, count: fileSize)
        } else {
            return nil
        }
        #endif
    }
}
