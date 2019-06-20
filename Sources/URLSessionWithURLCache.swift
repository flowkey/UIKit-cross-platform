//
//  URLSessionWithURLCache.swift
//  UIKit
//
//  Created by Chetan Agarwal on 20/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import Foundation

#if os(Android)
public typealias CachedURLResponse = FlowkeyCachedURLResponse
#endif

public class URLSessionWithURLCache: NSObject, URLSessionDataDelegate {

    public var urlCache: URLCachePrototype
    private var session: URLSession!

    private var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?

    private lazy var data: Data? = Data()
    private var cachedResponse: CachedURLResponse?

    public init(configuration: URLSessionConfiguration,
                delegate: URLSessionDelegate? = nil,
                delegateQueue queue: OperationQueue? = nil) {
        self.urlCache = FlowkeyURLCache.shared
        super.init()

        let delegate = delegate ?? self
        let queue = queue ?? OperationQueue.main
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
    }

    public func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.completionHandler = completionHandler
        // URLSessionDelegate methods are not called when a `completionHandler` is provided
        // save the `completionHandler` for later use and call the "normal" method
        return session.dataTask(with: request)
    }

    private func handleResponseCompletion(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        self.completionHandler?(data, response, error)
        self.data = nil
        self.cachedResponse = nil
        self.completionHandler = nil
    }

    // MARK: URLSessionDataDelegate

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.data?.append(data)
    }

    public func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let request = dataTask.originalRequest,
            let previouslyCachedResponse = urlCache.cachedResponse(for: request) else {
                return completionHandler(.allow)
        }
        // TODO: Check cache policy / etag etc. of the cached response to confirm it can be used
        self.cachedResponse = previouslyCachedResponse
        completionHandler(.cancel)
    }

    public func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let cachedResponse = self.cachedResponse else {
            saveToUrlCache(task: task)
            handleResponseCompletion(self.data, task.response, error)
            return
        }
        self.completionHandler?(cachedResponse.data, cachedResponse.response, nil)
    }

    private func saveToUrlCache(task: URLSessionTask) {
        guard
            let request = task.originalRequest,
            let response = task.response,
            let data = self.data else {
                return assertionFailure("cannot save task \(task) to cache")
        }

        let proposedResponse = CachedURLResponse(response: response, data: data)
        self.urlCache.storeCachedResponse(proposedResponse, for: request)
    }
}

internal class FlowkeyURLCache: URLCachePrototype {

    static var shared: URLCachePrototype = FlowkeyURLCache(memoryCapacity: 1000, diskCapacity: 1000, diskPath: nil)

    required init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        print("init FlowkeyURLCache")
    }

    func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        print("search for previously cached response for \(request.url!)")
        guard let url = request.url else { return nil }
        let responseDataFile = getResponseDataFile(for: url)
        guard let response = NSKeyedUnarchiver.unarchiveObject(withFile: responseDataFile.path) as? URLResponse else {
            print("response object not found in cache", responseDataFile.path)
            return nil
        }
        print("got previously saved response", response.expectedContentLength)

        let cacheFile = getCacheFile(for: url)
        guard let data = try? Data(contentsOf: cacheFile) else {
            print("file has no data")
            return nil
        }
        return CachedURLResponse(response: response, data: data)
    }

    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        print("store cached response")
        guard let url = request.url else { return }
        let responseDataFile = getResponseDataFile(for: url)
        guard NSKeyedArchiver.archiveRootObject(cachedResponse.response, toFile: responseDataFile.path) else {
            return assertionFailure("Unable to save response")
        }

        let cacheFile = getCacheFile(for: url)
        guard FileManager.default.createFile(atPath: cacheFile.path, contents: cachedResponse.data) else {
            return assertionFailure("Unable to save font file")
        }
    }

    private func getCacheFile(for url: URL) -> URL {
        let fontCacheDir = getFontsCacheDir()
        return fontCacheDir.appendingPathComponent(url.lastPathComponent, isDirectory: false)
    }

    private func getResponseDataFile(for url: URL) -> URL {
        let cacheFile = getCacheFile(for: url)
        return cacheFile.deletingPathExtension().appendingPathExtension("response")
    }

    private func getFontsCacheDir() -> URL {
        guard let cacheDir = getCachesDir() else {
            fatalError("no caches dir")
        }
        let fontCacheDir = cacheDir.appendingPathComponent("fonts")
        try!  FileManager.default.createDirectory(at: fontCacheDir,
                                                  withIntermediateDirectories: true)
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


public protocol URLCachePrototype {
    func cachedResponse(for request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest)
}

public struct FlowkeyCachedURLResponse {
    var response: URLResponse
    var data: Data

    init(response: URLResponse, data: Data) {
        self.response = response
        self.data = data
    }
}
