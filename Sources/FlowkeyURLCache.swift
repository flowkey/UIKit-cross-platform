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

    static var shared: URLCachePrototype = FlowkeyURLCache(memoryCapacity: 1000, diskCapacity: 1000, diskPath: nil)

    required init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        print("init FlowkeyURLCache")
    }

    func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        print("search for previously cached response for \(request.url!)")
        guard let url = request.url else {
            assertionFailure("request has no url")
            return nil
        }
        let responseDataFile = getResponseDataFile(for: url)
        let cachedResponse = NSKeyedUnarchiver.unarchiveObject(withFile: responseDataFile.path) as? CachedURLResponse

        if cachedResponse == nil {
            print("no cached response found")
        } else {
            print("cached response found!")
        }

        return cachedResponse
    }

    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        print("store cached response")
        guard let url = request.url else { return }
        let responseDataFile = getResponseDataFile(for: url)
        guard NSKeyedArchiver.archiveRootObject(cachedResponse, toFile: responseDataFile.path) else {
            return assertionFailure("Unable to save response")
        }
        print("stored cached response")
    }

    private func getResponseDataFile(for url: URL) -> URL {
        let cacheFile = getCacheDir().appendingPathComponent(url.lastPathComponent)
        return cacheFile.deletingPathExtension().appendingPathExtension("response")
    }

    private func getCacheDir() -> URL {
        guard let cacheDir = getCachesDir() else {
            fatalError("no caches dir")
        }
        let fontCacheDir = cacheDir.appendingPathComponent("fonts")
        try! FileManager.default.createDirectory(at: fontCacheDir, withIntermediateDirectories: true)
        return fontCacheDir
    }

    private func getCachesDir() -> URL? {
        #if os(Android)
        return AndroidFileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first
        #else
        return FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first
        #endif
    }
}
