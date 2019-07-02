//
//  URLDiskCacheTests.swift
//  UIKitTests
//
//  Created by Chetan Agarwal on 26/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class URLDiskCacheTests: XCTestCase {

    var directory: URL!
    var cache: URLDiskCache!
    var fileManager: FileManager!
    var urlForTesting: URL!

    override func setUp() {
        fileManager = FileManager.default

        let temporaryDirctory
            = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("cache-store-tests")
        
        cache = URLDiskCache(capacity: 100000, at: temporaryDirctory)
        directory = temporaryDirctory
        urlForTesting = URL(string: "http://fake.url")!
    }

    override func tearDown() {
        try? cache.removeAll()
        cache = nil
        directory = nil
        fileManager = nil
        urlForTesting = nil
    }

    func testCache_WhenInitialized_CreatesSubDirectories() {
        let responsesPath = directory.appendingPathComponent("fsResponses").path
        XCTAssertTrue(fileManager.fileExists(atPath: responsesPath))

        let dataPath = directory.appendingPathComponent("fsData").path
        XCTAssertTrue(fileManager.fileExists(atPath: dataPath))
    }

    func testCache_SavesEntry() {
        XCTAssertEqual(cache.cachedEntries.count, 0)
        let testData = createTestEntryAndResponse(for: urlForTesting)
        cache.storeCachedResponse(testData.response, for: testData.entry)
        XCTAssertEqual(cache.cachedEntries.count, 1)
        let entry = cache.cachedEntries.first!

        XCTAssertEqual(entry.requestKey, urlForTesting.absoluteString)
        XCTAssertNotNil(entry.uuid)
    }

    func testCache_ReturnsPreviouslyCachedResponse() {
        let testData = createTestEntryAndResponse(for: urlForTesting)
        cache.storeCachedResponse(testData.response, for: testData.entry)
        XCTAssertEqual(cache.cachedEntries.count, 1)

        let entryThatShouldBeFound = createTestEntry(for: urlForTesting)
        let cachedResponse = cache.getCachedResponse(for: entryThatShouldBeFound)
        let cachedResponseToBeSaved = testData.response

        XCTAssertNotNil(cachedResponse)
        
        XCTAssertEqual(cachedResponse?.response.url,cachedResponseToBeSaved.response.url)
        XCTAssertEqual(cachedResponse?.data, cachedResponseToBeSaved.data)
    }

    func testCache_CanLoadCachedEntriesFromPreviouslySavedJsonFile() {
        for i in 1...5 {
            let testUrl = URL(string: "http://fake\(i).url")!
            let testData = createTestEntryAndResponse(for: testUrl)
            cache.storeCachedResponse(testData.response, for: testData.entry)
        }
        XCTAssertEqual(cache.cachedEntries.count, 5)

        // There should be a json file created now
        // Creating another store instance should read the same json file
        let anotherCacheInstanceAtSameLocation = URLDiskCache(capacity: 100000, at: directory)
        
        XCTAssertEqual(anotherCacheInstanceAtSameLocation.cachedEntries.count, 5)
    }

    func testCache_RemovesSpecifiedEntryAndRelatedFiles() {
        for i in 1...5 {
            let testUrl = URL(string: "http://fake\(i).url")!
            let testData = createTestEntryAndResponse(for: testUrl)
            cache.storeCachedResponse(testData.response, for: testData.entry)
        }
        let urlToDelete = URL(string: "http://fake3.url")!
        let entryToDelete = createTestEntry(for: urlToDelete)

        XCTAssertEqual(cache.cachedEntries.count, 5)
        XCTAssertTrue(cache.cachedEntries.contains(entryToDelete))


        cache.removeCachedResponse(for: entryToDelete)

        XCTAssertEqual(cache.cachedEntries.count, 4)
        XCTAssertFalse(cache.cachedEntries.contains(entryToDelete))

        let responsesPath = directory.appendingPathComponent("fsResponses").path
        let dataPath = directory.appendingPathComponent("fsData").path

        let contentOfResponsesDir = try! fileManager.contentsOfDirectory(atPath: responsesPath)
        let contentOfDataDir = try! fileManager.contentsOfDirectory(atPath: dataPath)
        XCTAssertEqual(contentOfResponsesDir.count, 4)
        XCTAssertEqual(contentOfDataDir.count, 4)
    }

    func testCache_RemovesAllEntriesAndFiles() {
        for i in 1...5 {
            let testUrl = URL(string: "http://fake\(i).url")!
            let testData = createTestEntryAndResponse(for: testUrl)
            cache.storeCachedResponse(testData.response, for: testData.entry)
        }
        XCTAssertEqual(cache.cachedEntries.count, 5)

        try? cache.removeAll()

        verifyCacheAndDirectoriesAreEmpty()
    }

    func testCache_RemovesEntryWhenResourceFilesAreDeleted() {
        let testData = createTestEntryAndResponse(for: urlForTesting)
        cache.storeCachedResponse(testData.response, for: testData.entry)
        XCTAssertEqual(cache.cachedEntries.count, 1)

        // delete a resource file
        let entry = cache.cachedEntries.first!
        let pathToResponseFile = directory.appendingPathComponent("fsResponses").appendingPathComponent(entry.uuid!)
        try! FileManager.default.removeItem(atPath: pathToResponseFile.path)

        let cachedResponse = cache.getCachedResponse(for: testData.entry)
        XCTAssertNil(cachedResponse)

        verifyCacheAndDirectoriesAreEmpty()
    }

    // MARK: Utility

    func verifyCacheAndDirectoriesAreEmpty() {
        XCTAssertEqual(cache.cachedEntries.count, 0)

        let responsesPath = directory.appendingPathComponent("fsResponses").path
        let dataPath = directory.appendingPathComponent("fsData").path

        let contentOfResponsesDir = try! fileManager.contentsOfDirectory(atPath: responsesPath)
        let contentOfDataDir = try! fileManager.contentsOfDirectory(atPath: dataPath)
        XCTAssertTrue(contentOfResponsesDir.isEmpty)
        XCTAssertTrue(contentOfDataDir.isEmpty)
    }

    func createTestEntry(for url: URL) -> CacheEntry {
        let request = URLRequest(url: url)
        return CacheEntry(for: request)!
    }

    func createTestEntryAndResponse(for url: URL) -> (entry: CacheEntry, response: CachedURLResponse) {
        let data = "this is a test".data(using: .utf8)!
        let response = URLResponse(url: url,
                                   mimeType: "text/plain",
                                   expectedContentLength: data.count,
                                   textEncodingName: String.Encoding.utf8.description)

        let cachedResponse = CachedURLResponse(response: response, data: data)
        let request = URLRequest(url: url)
        let cacheEntry = CacheEntry(for: request, saving: cachedResponse)!
        return (cacheEntry, cachedResponse)
    }
}
