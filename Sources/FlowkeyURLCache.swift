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
            guard let entry = CacheEntry(for: request, saving: cachedResponse) else { return }
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
    var requestKey: String

    var id: Int?
    var timeStamp: Date?
    var storagePolicy: UInt?

    var uuid: String?

    init?(for request: URLRequest) {
        guard let url = request.url else { return nil }
        self.requestKey = url.absoluteString
    }

    convenience init?(for request: URLRequest, saving response: CachedURLResponse) {
        self.init(for: request)
        self.storagePolicy = response.storagePolicy.rawValue
        self.timeStamp = Date()
    }

    #if !os(Android)
    // Hasher in not available in Foundation yet
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.requestKey)
    }
    #else
    var hashValue: Int {
        return requestKey.hashValue
    }
    #endif



    static func == (lhs: CacheEntry, rhs: CacheEntry) -> Bool {
        return lhs.requestKey == rhs.requestKey
    }
}

/**
 Mimics behaviour of iOS URLCache - which uses an SQLite database to save similar data.
 This implementation uses json but can be replaced in the future to use SQLite if needed.
 **/
class CacheStore {

    enum CachesFileType {
        case response
        case data
    }

    private (set) var cachedEntries: Set<CacheEntry>
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
        guard let cachedEntry = findPreviouslyCachedEntry(for: entry) else { return nil }

        guard
            let response = readResponseFromFile(for: cachedEntry),
            let data = readDataFromFile(for: cachedEntry)
            else {
                // TODO: remove the cache entry and any associated files
                return nil
        }
        return CachedURLResponse(response: response, data: data)
    }

    func removeAll() throws {
        try FileManager.default.removeItem(at: dataFile)
        try FileManager.default.removeItem(at: responsesDirectory)
        try FileManager.default.removeItem(at: responseDataFilesDirectory)
        self.cachedEntries.removeAll()
        loadSavedCachedEntriesFromFile()
    }

    private func findPreviouslyCachedEntry(for entry: CacheEntry) -> CacheEntry? {
        return cachedEntries.first { entry.requestKey == $0.requestKey }
    }

    // MARK: File operations

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
            // TODO: should delete the JSON and other files?
            assertionFailure("Readimg JSON Cache data from file failed: \(error)")
        }
    }

    private func saveUpdatedEntriesToFile() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self.cachedEntries)
            _ = FileManager.default.createFile(atPath: dataFile.path,
                                               contents: data,
                                               attributes: nil)
        } catch {
            assertionFailure("Writing JSON Cache data to file failed: \(error)")
        }
    }

    private func saveResponseToFile(entry: CacheEntry, response: URLResponse) {
        guard let file = getFile(ofType: .response, for: entry) else { return }
        guard NSKeyedArchiver.archiveRootObject(response, toFile: file.path) else {
            return assertionFailure("Could not serialize response")
        }
    }

    private func readResponseFromFile(for entry: CacheEntry) -> URLResponse? {
        guard let file = getFile(ofType: .response, for: entry, ensureExists: true) else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(withFile: file.path) as? URLResponse
    }

    private func saveDataToFile(entry: CacheEntry, data: Data) {
        guard let file = getFile(ofType: .data, for: entry) else { return }
        guard FileManager.default.createFile(atPath: file.path, contents: data) else {
            return assertionFailure("Could not save response data to file")
        }
    }

    private func readDataFromFile(for entry: CacheEntry) -> Data?  {
        guard let file = getFile(ofType: .data, for: entry, ensureExists: true) else { return nil }
        return try? Data(contentsOf: file)
    }

    private func getDirectory(for type: CachesFileType) -> URL {
        switch type {
        case .response:
            return responsesDirectory
        case .data:
            return responseDataFilesDirectory
        }
    }

    private func getFile(ofType type: CachesFileType, for entry: CacheEntry, ensureExists: Bool = false) -> URL? {
        guard let filename = entry.uuid else {
            assertionFailure("trying to save file with no uuid")
            return nil
        }

        let directory = getDirectory(for: type)
        let file = directory.appendingPathComponent(filename)


        if ensureExists {
            let validFileExists = FileManager.default.isReadableFile(atPath: file.path)
            return validFileExists ? file : nil
        } else {
            return file
        }
    }
}
