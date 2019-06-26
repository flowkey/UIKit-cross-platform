//
//  CacheStoreTests.swift
//  UIKitTests
//
//  Created by Chetan Agarwal on 26/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class CacheStoreTests: XCTestCase {

    var directory: URL!
    var store: CacheStore!
    var fileManager: FileManager!
    var urlForTesting: URL!


    override func setUp() {
        fileManager = FileManager.default

        let temporaryDirctory
            = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("cache-store-tests")
        
        store = CacheStore(at: temporaryDirctory)
        directory = temporaryDirctory
        urlForTesting = URL(string: "http://fake.url")!
    }

    override func tearDown() {
        try? store.removeAll()
        store = nil
        directory = nil
        fileManager = nil
        urlForTesting = nil
    }

    func testStore_WhenInitialized_CreatesSubDirectories() {
        let responsesPath = directory.appendingPathComponent("fsResponses").path
        XCTAssertTrue(fileManager.fileExists(atPath: responsesPath))

        let dataPath = directory.appendingPathComponent("fsData").path
        XCTAssertTrue(fileManager.fileExists(atPath: dataPath))
    }

    func testStore_SavesEntry() {
        XCTAssertEqual(store.cachedEntries.count, 0)
        let data = getTestData(url: urlForTesting)
        store.save(entry: data.0, cachedResponse: data.1!)
        XCTAssertEqual(store.cachedEntries.count, 1)
        let entry = store.cachedEntries.first!

        XCTAssertEqual(entry.requestKey, urlForTesting.absoluteString)
        XCTAssertNotNil(entry.uuid)
    }

    func testStore_ReturnsPreviouslyCachesResponse() {
        let data = getTestData(url: urlForTesting)
        store.save(entry: data.0, cachedResponse: data.1!)
        XCTAssertEqual(store.cachedEntries.count, 1)

        let entryThatShouldNOTBeFound = getTestData(url: URL(string: "http://notsaved.url")!).0
        XCTAssertNil(store.find(entry: entryThatShouldNOTBeFound))

        let entryThatShouldBeFound = getTestData(url: urlForTesting).0
        let cachedResponseFromStore = store.find(entry: entryThatShouldBeFound)

        let expectedResponse = data.1
        XCTAssertNotNil(cachedResponseFromStore)
        XCTAssertEqual(cachedResponseFromStore?.response.url, expectedResponse?.response.url)
        XCTAssertEqual(cachedResponseFromStore?.data, cachedResponseFromStore?.data)
    }

    func testStore_CanLoadCachedEntriesFromPreviouslySavedJsonFile() {
        for i in 1...5 {
            let testUrl = URL(string: "http://fake\(i).url")!
            let data = getTestData(url: testUrl)
            store.save(entry: data.0, cachedResponse: data.1!)
        }
        XCTAssertEqual(store.cachedEntries.count, 5)
        // There should be a json file created now
        // Creating another store instance should read the same json file
        let anotherStoreInstance = CacheStore(at: directory)
        
        XCTAssertEqual(anotherStoreInstance.cachedEntries.count, 5)
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
