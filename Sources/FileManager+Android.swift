//
//  FileManager+Android.swift
//  UIKit
//
//  Created by Chetan Agarwal on 07/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

#if os(Android)

import Foundation

public final class AndroidFileManager: FileManager {
    private static var instance = AndroidFileManager()

    public static override var `default`: FileManager {
        return instance
    }

    public override func urls(for directory: FileManager.SearchPathDirectory,
                              in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        guard let url = try? getDirectory(ofType: directory) else {
            return []
        }
        return [url]
    }

    func getDirectory(ofType type: FileManager.SearchPathDirectory) throws -> URL {
        let context = try AndroidContext.getContext()

        let file: JavaFile!

        switch type {
        case .cachesDirectory:
            file = try context.getCacheDir()
        case .documentDirectory:
            file = try context.getFilesDir()
        default:
            fatalError("Dir type: 'FileManager.SearchPathDirectory.\(type)' is not implemented yet.")
        }
        let dirPath = try file.getAbsolutePath()
        return URL(fileURLWithPath: dirPath)
    }
}
#endif
