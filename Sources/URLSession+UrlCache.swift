//
//  URLSession+UrlCache.swift
//  UIKit
//
//  Created by Chetan Agarwal on 20/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import Foundation

public class URLSessionWrapperWithCustomURLCache: NSObject, URLSessionDataDelegate {

    private var wrappedSession: URLSession!

    var urlCache: URLCachePrototype
    var taskRegistry: URLSessionWrapperWithCustomURLCache.TaskRegistry!

    public init(configuration: URLSessionConfiguration,
                delegate: URLSessionDelegate? = nil,
                delegateQueue queue: OperationQueue? = nil) {
        #if os(Android)
        self.urlCache = FlowkeyURLCache.shared
        #else
        self.urlCache = configuration.urlCache ?? FlowkeyURLCache.shared
        #endif

        super.init()

        self.taskRegistry = TaskRegistry()
        let queue = queue ?? OperationQueue.main
        self.wrappedSession = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
    }

    public func dataTask(with request: URLRequest,
                         completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        // URLSessionDelegate methods are not called when a `completionHandler` is provided when creating a data task.
        // Save the `completionHandler` for later use and create the data task using the non-delegate method.
        let task = wrappedSession.dataTask(with: request)
        taskRegistry.register(task: task, onComplete: completionHandler)
        #if os(Android)
        return URLTaskWrapper(session: self, task: task)
        #else
        return task
        #endif
    }

    public func finishTasksAndInvalidate() {
        wrappedSession?.finishTasksAndInvalidate()
    }

    public func invalidateAndCancel() {
        wrappedSession?.invalidateAndCancel()
    }

    // MARK: URLSessionDataDelegate

    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        taskRegistry.received(data: data, for: dataTask)
    }

    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let request = dataTask.originalRequest,
            let previouslyCachedResponse = urlCache.cachedResponse(for: request),
            previouslyCachedResponse.canBeReusedFor(response: response) else {
                completionHandler(.allow)
                return
        }
        completionHandler(.cancel)
        taskRegistry.received(cachedResponse: previouslyCachedResponse, for: dataTask)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        taskRegistry.completeAndRemove(task: task, with: task.response, or: error) { (task, data) in
            self.saveToUrlCache(task: task, data: data)
        }
    }

    public func urlSession(_ session: URLSession,
                           didBecomeInvalidWithError error: Error?) {
        // wrapped session finished invalidating, cleanup own resources
        taskRegistry = nil
        wrappedSession = nil
    }
    
    private func saveToUrlCache(task: URLSessionTask, data: Data?) {
        guard
            let request = task.originalRequest,
            let response = task.response,
            let data = data
        else {
                return assertionFailure("cannot save task \(task) to cache")
        }

        let cachedResponseToSave = CachedURLResponse(response: response, data: data)
        self.urlCache.storeCachedResponse(cachedResponseToSave, for: request)
    }
}

class URLTaskWrapper: URLSessionDataTask {
    var session: URLSessionWrapperWithCustomURLCache
    var originalTask: URLSessionDataTask

    init(session: URLSessionWrapperWithCustomURLCache, task: URLSessionDataTask) {
        self.originalTask = task
        self.session = session
        super.init()
    }

    override func resume() {
        guard let request = originalTask.originalRequest else { return }
        guard
            let url = request.url,
            let cachedResponse = self.session.urlCache.cachedResponse(for: request)
        else {
            return originalTask.resume()
        }

        // There is a previously cached response, so only get headers to compare if it's still usable
        // Currently only the ETag header is compared.
        let session = URLSession.shared
        var headRequest = URLRequest(url: url)
        headRequest.httpMethod = "HEAD"
        session.dataTask(with: headRequest) { (data, response, error) in

            if let error = error {
                if let urlError = error as? URLError,
                    urlError.code == .cannotFindHost || urlError.code == .cannotConnectToHost {
                    // Perhaps user if offline. use previously cached response as fallback?
                    // TODO: Add check for `Cache-Control: max-age`?
                    self.session.taskRegistry.received(cachedResponse: cachedResponse,for: self.originalTask)
                    self.originalTask.cancel()
                } else {
                    self.originalTask.resume()
                }
                return
            }

            guard
                let response = response,
                cachedResponse.canBeReusedFor(response: response)
            else {
                    self.originalTask.resume()
                    return
            }
            self.session.taskRegistry.received(cachedResponse: cachedResponse, for: self.originalTask)
            self.originalTask.cancel()
        }.resume()
    }
}

private extension CachedURLResponse {
    func canBeReusedFor(response: URLResponse) -> Bool {
        guard
            let cachedHTTPResponse = self.response as? HTTPURLResponse,
            let targetHTTPResponse = response as? HTTPURLResponse,
            let cachedResponseEtag = cachedHTTPResponse.value(forHeaderField: "ETag"),
            let targetResponseEtag = targetHTTPResponse.value(forHeaderField: "ETag")
        else { return false }
        return cachedResponseEtag == targetResponseEtag
    }
}

private extension HTTPURLResponse {
    // HTTP Headers are case-insesitive
    func value(forHeaderField field: String) -> String? {
        let httpHeaderField = allHeaderFields.first { (key, value) -> Bool in
            guard let keyAsString = key as? String else { return false }
            return field.caseInsensitiveCompare(keyAsString) == .orderedSame
        }
        return httpHeaderField?.value as? String
    }
}
