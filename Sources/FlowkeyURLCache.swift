//
//  FlowkeyURLCache.swift
//  UIKit
//
//  Created by Chetan Agarwal on 24/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import Foundation

public protocol URLCachePrototype {
    func cachedResponse(for request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest)
}

#if !os(Android)
extension URLCache: URLCachePrototype {}
#endif

internal class FlowkeyURLCache: URLCachePrototype {

    static var shared: URLCachePrototype
        = FlowkeyURLCache(memoryCapacity: 0, diskCapacity: 1024 * 1024 * 50, diskPath: nil)

    private var diskCache: DiskCache?

    required init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        if memoryCapacity > 0 {
            assertionFailure("Memory cache is not supported yet. This is a disk only cache.")
        }

        if diskCapacity > 0 {
            self.diskCache = DiskCache(capacity: diskCapacity, path: path)
        }
    }

    func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        return diskCache?.cachedResponse(for: request)
    }

    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        diskCache?.storeCachedResponse(cachedResponse, for: request)
    }
}

extension FlowkeyURLCache {

    class DiskCache {

        let capacity: Int
        let cacheDirectory: URL

        init(capacity: Int, path: String?) {
            self.capacity = capacity
            if let path = path {
                self.cacheDirectory = URL(fileURLWithPath: path)
            } else {
                let caches = DiskCache.platformSpecificCachesDirectory
                let cacheName = "com.flowkey.urlcache" // Avoid colision with any other file caches
                let cacheDirectory = caches.appendingPathComponent(cacheName, isDirectory: true)
                try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
                self.cacheDirectory = cacheDirectory
            }
        }

        func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
            guard let url = request.url else {
                assertionFailure("request has no url")
                return nil
            }
            print(url.absoluteString, url.hashValue)

            let responseDataFile = getResponseDataFile(for: url)
            return NSKeyedUnarchiver.unarchiveObject(withFile: responseDataFile.path) as? CachedURLResponse
        }

        func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
            guard let url = request.url else { return }
            let responseDataFile = getResponseDataFile(for: url)
            guard NSKeyedArchiver.archiveRootObject(cachedResponse, toFile: responseDataFile.path) else {
                return assertionFailure("Unable to save response")
            }
        }

        private func getResponseDataFile(for url: URL) -> URL {
            let cacheFile = cacheDirectory.appendingPathComponent(url.lastPathComponent)
            return cacheFile.deletingPathExtension().appendingPathExtension("response")
        }

        static var platformSpecificCachesDirectory: URL {
            #if os(Android)
            return AndroidFileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            #elseif os(macOS)
            // On MacOS the caches directory is shared by all apps. Ex: `~/Library/Caches`
            // It's recommened to create a sub-directory derived from bundle identifier
            // Ex: `~/Library/Caches/com.flowkey.MacTestApp`
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            guard let dirForBundle = Bundle.directoryNameFromBundleIdentifier else { return caches }
            let cachesDirForBundle = caches.appendingPathComponent(dirForBundle, isDirectory: true)
            try? FileManager.default.createDirectory(at: cachesDirForBundle, withIntermediateDirectories: true)
            return cachesDirForBundle
            #else
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            #endif
        }
    }
}

#if !os(Android)
extension Bundle {
    static var directoryNameFromBundleIdentifier: String? {
        guard
            let identifier = Bundle.main.bundleIdentifier,
            let regex = try? NSRegularExpression(pattern: "[^a-zA-Z0-9_.]+", options: [])
            else {
                return nil
        }
        return regex.stringByReplacingMatches(in: identifier,
                                              options: [],
                                              range: NSRange(location: 0, length: identifier.count),
                                              withTemplate: "_")
    }
}
#endif
