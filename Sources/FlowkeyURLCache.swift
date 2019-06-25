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
        let store: CacheStore

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
            self.store = CacheStore(at: self.cacheDirectory)
        }

        func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
            guard let entry = CacheEntry(for: request) else { return nil }
            return store.find(entry: entry)
        }

        func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
            guard let entry = CacheEntry(for: request) else { return }
            entry.fill(with: cachedResponse)
            store.save(entry: entry, cachedResponse: cachedResponse)
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

class CacheEntry: Hashable, Codable {
    var hashValue: Int
    var requestKey: String

    var id: Int?
    var timeStamp: Date?
    var storagePolicy: UInt?

    var uuid: String?

    init?(for request: URLRequest) {
        guard let url = request.url else { return nil }
        self.hashValue = url.hashValue
        self.requestKey = url.absoluteString
    }

    func fill(with cachedResponse: CachedURLResponse) {
        self.storagePolicy = cachedResponse.storagePolicy.rawValue
        self.timeStamp = Date()
    }

    #if !os(Android)
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.hashValue)
    }
    #endif

    static func == (lhs: CacheEntry, rhs: CacheEntry) -> Bool {
        let isEqual = lhs.hashValue == rhs.hashValue &&
            lhs.requestKey == rhs.requestKey &&
            lhs.storagePolicy == rhs.storagePolicy &&
            lhs.timeStamp == rhs.timeStamp &&
            lhs.id == rhs.id
        return isEqual
    }
}

/**
 Mimics behaviour of iOS URLCache - which uses an SQLite database to save similar data.
 This implementation uses json but can be replaced in the future to use SQLite if needed.
 **/
class CacheStore {

    private var cachedEntries: Set<CacheEntry>
    private var dataFile: URL
    private var responsesDirectory: URL
    private var responseDataFilesDirectory: URL

    init(at url: URL) {
        self.dataFile = url.appendingPathComponent("Cache.db.json", isDirectory: false)
        self.responsesDirectory = url.appendingPathComponent("fsResponses", isDirectory: true)
        self.responseDataFilesDirectory = url.appendingPathComponent("fsData", isDirectory: true)

        try? FileManager.default.createDirectory(at: self.responsesDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: self.responseDataFilesDirectory, withIntermediateDirectories: true)

        self.cachedEntries = Set<CacheEntry>()
        loadSavedCachedEntriesFromFile()
    }

    func save(entry: CacheEntry, cachedResponse: CachedURLResponse) {
        entry.id = cachedEntries.count + 1
        entry.uuid = UUID().uuidString
        cachedEntries.insert(entry)
        saveResponseToFile(entry: entry, response: cachedResponse.response)
        saveDataToFile(entry: entry, data: cachedResponse.data)
        saveUpdatedEntriesToFile()
    }

    func find(entry: CacheEntry) -> CachedURLResponse? {
        return nil
    }

    private func hasPreviouslySavedData() -> Bool {
        return FileManager.default.isReadableFile(atPath: dataFile.path)
    }

    private func loadSavedCachedEntriesFromFile() {
        guard hasPreviouslySavedData() else { return }
        do {
            let data = try Data(contentsOf: dataFile)
            let decoder = JSONDecoder()
            let entries = try decoder.decode(Set<CacheEntry>.self, from: data)
            print(entries.count)
            self.cachedEntries = self.cachedEntries.union(entries)
        } catch {
            print(error)
        }
    }

    private func saveResponseToFile(entry: CacheEntry, response: URLResponse) {
        guard let filename = entry.uuid else { return assertionFailure("trying to save file with no uuid") }
        let responseFile = responsesDirectory.appendingPathComponent(filename)
        NSKeyedArchiver.archiveRootObject(response, toFile: responseFile.path)
    }

    private func saveDataToFile(entry: CacheEntry, data: Data) {
        guard let filename = entry.uuid else { return assertionFailure("trying to save file with no uuid") }
        let dataFile = responseDataFilesDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: dataFile.path, contents: data)
    }

    private func saveUpdatedEntriesToFile() {
        print("update the json file?")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self.cachedEntries)
            let jsonString = String(data: data, encoding: .utf8)
            print(jsonString ?? "no data")
            FileManager.default.createFile(atPath: dataFile.path,
                                           contents: data,
                                           attributes: nil)
        } catch {
            print(error)
        }
    }
}
