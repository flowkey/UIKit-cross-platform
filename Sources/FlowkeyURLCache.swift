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
    func removeCachedResponse(for request: URLRequest)
    func removeAllCachedResponses()

    var diskCapacity: Int { get set }
    var currentDiskUsage: Int { get }
}

#if !os(Android)
extension URLCache: URLCachePrototype {}
#endif

internal class FlowkeyURLCache: URLCachePrototype {

    var diskCapacity: Int {
        get {
            return diskCache?.capacity ?? 0
        }
        set {
            diskCache?.capacity = newValue
        }
    }

    var currentDiskUsage: Int {
        return diskCache?.getCurrentDiskUsage() ?? 0
    }

    static var shared: URLCachePrototype
        = FlowkeyURLCache(memoryCapacity: 0, diskCapacity: 1024 * 1024 * 50, diskPath: nil)

    private var diskCache: URLDiskCache?

    required init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        if memoryCapacity > 0 {
            assertionFailure("Memory cache is not supported yet. This is a disk only cache.")
        }
        self.diskCapacity = diskCapacity
        initDiskCache(capacity: diskCapacity, path: path)
    }

    private func initDiskCache(capacity: Int, path: String?) {
        guard capacity > 0 else { return }

        if let path = path {
            let cacheDirectory = URL(fileURLWithPath: path)
            self.diskCache = URLDiskCache(capacity: capacity, at: cacheDirectory)
            return
        }

        guard let rootCachesDir = FlowkeyURLCache.platformSpecificCachesDirectory else {
            return assertionFailure("Could not find caches dir.")
        }
        let cacheName = "com.flowkey.urlcache" // Avoid colision with any other file caches
        let cacheDirectory = rootCachesDir.appendingPathComponent(cacheName, isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        self.diskCache = URLDiskCache(capacity: capacity, at: cacheDirectory)
    }

    func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        guard let entry = CacheEntry(for: request) else { return nil }
        return diskCache?.getCachedResponse(for: entry)
    }

    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        guard let entry = CacheEntry(for: request, saving: cachedResponse) else { return }
        diskCache?.storeCachedResponse(cachedResponse, for: entry)
    }

    func removeCachedResponse(for request: URLRequest) {
        guard let entry = CacheEntry(for: request) else { return }
        diskCache?.removeCachedResponse(for: entry)
    }

    func removeAllCachedResponses() {
        try? diskCache?.removeAll()
    }

    static var platformSpecificCachesDirectory: URL? {
        #if os(Android)
        return AndroidFileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        #elseif os(macOS)
        // On MacOS the caches directory is shared by all apps. Ex: `~/Library/Caches`
        // It's recommened to create a sub-directory derived from bundle identifier
        // Ex: `~/Library/Caches/com.flowkey.MacTestApp`
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        guard let dirForBundle = Bundle.directoryNameFromBundleIdentifier else { return caches }
        let cachesDirForBundle = caches.appendingPathComponent(dirForBundle, isDirectory: true)
        try? FileManager.default.createDirectory(at: cachesDirForBundle, withIntermediateDirectories: true)
        return cachesDirForBundle
        #else
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        #endif
    }
}

/**
 Mimics behaviour of iOS URLCache - which uses an SQLite database to save similar data.
 This implementation uses json but can be replaced in the future to use SQLite if needed.
 **/
internal class URLDiskCache {

    var capacity: Int {
        didSet {
            guard cachedEntries.count > 0 else { return }
            trimCache(to: capacity)
        }
    }

    let cacheDirectory: URL

    private (set) var cachedEntries: Set<CacheEntry>
    private var dataFile: URL

    init(capacity: Int, at url: URL) {
        self.capacity = capacity
        self.cacheDirectory = url
        self.dataFile = url.appendingPathComponent("Cache.db.json", isDirectory: false)
        self.cachedEntries = Set<CacheEntry>()
        self.createRequiredSubDirectories()
        loadSavedCachedEntriesFromFile()
    }

    fileprivate func createRequiredSubDirectories() {
        CachesFileType.allCases.forEach {
            let targetDir = $0.getResourceDirectory(baseDirectory: cacheDirectory)
            try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }
    }

    func getCachedResponse(for entry: CacheEntry) -> CachedURLResponse? {
        guard let cachedEntry = findPreviouslyCachedEntry(for: entry) else { return nil }

        guard
            let response = readResponseFromFile(for: cachedEntry),
            let data = readDataFromFile(for: cachedEntry)
            else {
                removeCachedResponse(for: cachedEntry)
                return nil
        }
        return CachedURLResponse(response: response, data: data)
    }

    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for entry: CacheEntry) {
        // check the disk cost of serialized version
        let costOfItem = NSKeyedArchiver.archivedData(withRootObject: cachedResponse).count
        trimCache(to: capacity - costOfItem)

        if let previousEntry = findPreviouslyCachedEntry(for: entry) {
            removeCachedResponse(for: previousEntry)
        }

        entry.uuid = UUID().uuidString
        cachedEntries.insert(entry)
        saveResponseToFile(entry: entry, response: cachedResponse.response)
        saveDataToFile(entry: entry, data: cachedResponse.data)
        saveUpdatedEntriesToFile()
    }

    private func getDiskCacheEntries(with keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]) -> [DiskCacheEntry] {
        let fileManager = FileManager.default
        var diskCacheEntries = [DiskCacheEntry]()

        CachesFileType.allCases.forEach {
            let dir = $0.getResourceDirectory(baseDirectory: cacheDirectory)
            guard let contentURLs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys) else { return }
            for url in contentURLs where url.isFileURL {
                let resourceValues = try! url.resourceValues(forKeys: Set<URLResourceKey>(keys))
                let identifier = url.lastPathComponent
                let date = resourceValues.contentModificationDate ?? Date(timeIntervalSince1970: 0)
                let fileSize = resourceValues.fileSize ?? 0

                let cacheEntry = self.cachedEntries.first(where: {
                    $0.uuid == identifier
                })

                let indexOfExistingDiskCacheEntry = diskCacheEntries.firstIndex(where: {
                    $0.identifier == identifier
                })

                if let index = indexOfExistingDiskCacheEntry {
                    var itemThatWasFound = diskCacheEntries[index]
                    itemThatWasFound.files.append(url)
                    itemThatWasFound.cost = itemThatWasFound.cost + fileSize
                    itemThatWasFound.date = min(date, itemThatWasFound.date)
                    diskCacheEntries[index] = itemThatWasFound
                } else {
                    let item = DiskCacheEntry(identifier: identifier, files: [url], date: date, cost: fileSize, cacheEntry: cacheEntry)
                    diskCacheEntries.append(item)
                }
            }
        }
        return diskCacheEntries
    }

    private func trimCache(to targetCapacity: Int) {
        let diskCacheItems = getDiskCacheEntries()
        var totalSize: Int = diskCacheItems.reduce(0) { return $0 + $1.cost }

        guard totalSize > targetCapacity else { return }

        let diskCachedItemsOrderedByAge = diskCacheItems.sorted { $0.date < $1.date }

        var cacheEntriesToRemove = [CacheEntry]()
        var orphanFilesToRemove = [URL]()

        for diskItem in diskCachedItemsOrderedByAge {

            if let cacheEntry = diskItem.cacheEntry {
                cacheEntriesToRemove.append(cacheEntry)
            } else {
                orphanFilesToRemove.append(contentsOf: diskItem.files)
            }

            totalSize -= diskItem.cost
            if totalSize < targetCapacity {
                break
            }
        }

        cacheEntriesToRemove.forEach { removeCachedResponse(for: $0) }
        orphanFilesToRemove.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    func removeCachedResponse(for entry: CacheEntry) {
        guard let cachedEntry = findPreviouslyCachedEntry(for: entry) else { return }
        if let responseFile = getFile(ofType: .urlResponse, for: cachedEntry) {
            try? FileManager.default.removeItem(at: responseFile)
        }
        if let dataFile = getFile(ofType: .data, for: cachedEntry) {
            try? FileManager.default.removeItem(at: dataFile)
        }
        self.cachedEntries.remove(cachedEntry)
    }

    func removeAll() throws {
        try FileManager.default.removeItem(at: dataFile)
        CachesFileType.allCases.forEach {
            let targetDir = $0.getResourceDirectory(baseDirectory: cacheDirectory)
            try? FileManager.default.removeItem(at: targetDir)
        }
        self.cachedEntries.removeAll()
        createRequiredSubDirectories()
        loadSavedCachedEntriesFromFile()
    }

    func getCurrentDiskUsage() -> Int {
        let diskCacheItems = getDiskCacheEntries(with: [.fileSizeKey])
        return diskCacheItems.reduce(0) { $0 + $1.cost }
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
            self.cachedEntries = self.cachedEntries.union(entries)
            trimCache(to: capacity)
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
            let saved = FileManager.default.createFile(atPath: dataFile.path, contents: data, attributes: nil)
            guard saved else { return assertionFailure("Couldn't write to \(dataFile.path)") }
        } catch {
            assertionFailure("Writing JSON Cache data to file failed: \(error)")
        }
    }

    private func saveResponseToFile(entry: CacheEntry, response: URLResponse) {
        guard let file = getFile(ofType: .urlResponse, for: entry) else { return }
        guard NSKeyedArchiver.archiveRootObject(response, toFile: file.path) else {
            return assertionFailure("Could not serialize response")
        }
    }

    private func readResponseFromFile(for entry: CacheEntry) -> URLResponse? {
        guard let file = getFile(ofType: .urlResponse, for: entry, ensureExists: true) else { return nil }
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

    private func getFile(ofType type: CachesFileType, for entry: CacheEntry, ensureExists: Bool = false) -> URL? {
        guard let filename = entry.uuid else {
            assertionFailure("trying to save file with no uuid")
            return nil
        }

        let file = type.getResourceFile(baseDirectory: cacheDirectory, filename: filename)

        if ensureExists {
            let validFileExists = FileManager.default.isReadableFile(atPath: file.path)
            return validFileExists ? file : nil
        } else {
            return file
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


extension URLDiskCache {
    enum CachesFileType {
        case urlResponse
        case data

        var directoryName: String {
            switch self {
            case .urlResponse:
                return "fsResponses"
            case .data:
                return "fsData"
            }
        }

        func getResourceDirectory(baseDirectory url: URL) -> URL {
            return url.appendingPathComponent(directoryName, isDirectory: true)
        }

        func getResourceFile(baseDirectory url: URL, filename: String) -> URL {
            let targetDirectory = getResourceDirectory(baseDirectory: url)
            return targetDirectory.appendingPathComponent(filename)
        }
    }
}

// the `CaseIterable` protocol automatically provides the `allCases` property.
// However it is not available on the Android version of Foudation yet.
#if os(Android)
extension URLDiskCache.CachesFileType {
    static let allCases: [URLDiskCache.CachesFileType] = [.urlResponse, .data]
}
#else
extension URLDiskCache.CachesFileType: CaseIterable {}
#endif

extension URLDiskCache {
    private struct DiskCacheEntry {
        var identifier: String
        var files: [URL]
        var date: Date
        var cost: Int
        var cacheEntry: CacheEntry?
    }
}
