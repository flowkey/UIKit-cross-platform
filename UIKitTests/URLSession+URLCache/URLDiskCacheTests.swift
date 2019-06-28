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
        let data = getTestData(url: urlForTesting)
        cache.storeCachedResponse(data.1!, for: data.0)
        XCTAssertEqual(cache.cachedEntries.count, 1)
        let entry = cache.cachedEntries.first!

        XCTAssertEqual(entry.requestKey, urlForTesting.absoluteString)
        XCTAssertNotNil(entry.uuid)
    }

    func testCache_ReturnsPreviouslyCachedResponse() {
        let data = getTestData(url: urlForTesting)
        cache.storeCachedResponse(data.1!, for: data.0)
        XCTAssertEqual(cache.cachedEntries.count, 1)

        let entryThatShouldNOTBeFound = getTestData(url: URL(string: "http://notsaved.url")!).0
        XCTAssertNil(cache.getCachedResponse(for: entryThatShouldNOTBeFound))

        let entryThatShouldBeFound = getTestData(url: urlForTesting).0
        let cachedResponse = cache.getCachedResponse(for: entryThatShouldBeFound)

        XCTAssertNotNil(cachedResponse)

        let saveResponse = data.1!
        XCTAssertEqual(cachedResponse?.response.url, saveResponse.response.url)
        XCTAssertEqual(cachedResponse?.data, saveResponse.data)
    }

    func testCache_CanLoadCachedEntriesFromPreviouslySavedJsonFile() {
        for i in 1...5 {
            let testUrl = URL(string: "http://fake\(i).url")!
            let data = getTestData(url: testUrl)
            cache.storeCachedResponse(data.1!, for: data.0)
        }
        XCTAssertEqual(cache.cachedEntries.count, 5)
        // There should be a json file created now
        // Creating another store instance should read the same json file
        let anotherCacheInstanceAtSameLocation = URLDiskCache(capacity: 100000, at: directory)
        
        XCTAssertEqual(anotherCacheInstanceAtSameLocation.cachedEntries.count, 5)
    }

    // MARK: Utility

    func getTestData(url: URL, withResponse: Bool = true) -> (CacheEntry, CachedURLResponse?) {
        let request = URLRequest(url: url)
        let cacheEntry = CacheEntry(for: request)!
        guard withResponse else {
            return (cacheEntry, nil)
        }

        let data = "this is a test".data(using: .utf8)!
        let response = URLResponse(url: url,
                                   mimeType: "text/plain",
                                   expectedContentLength: data.count,
                                   textEncodingName: String.Encoding.utf8.description)

        let fakeCachedURLResponse = CachedURLResponse(response: response, data: data)
        return (cacheEntry, fakeCachedURLResponse)
    }

}
