//
//  FileManager+Android.swift
//  UIKit
//
//  Created by Chetan Agarwal on 07/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import Foundation

public class AndroidFileManager: FileManager {

    private static var instance = AndroidFileManager()

    public static override var `default`: FileManager {
        return instance
    }

    public override func urls(for directory: FileManager.SearchPathDirectory,
                              in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        let fakePath = directory == .cachesDirectory ? "/caches" : "/docs"
        return [URL(fileURLWithPath: fakePath)]
    }
}
