//
//  FlowkeyCachedURLResponse.swift
//  UIKit
//
//  Created by Chetan Agarwal on 24/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import Foundation

#if os(Android)
// The `Foundation.CachedURLResponse` cannot be overridden, as the initializers throw `NSUnimplement` errors.
public typealias CachedURLResponse = FlowkeyCachedURLResponse
#endif

public class FlowkeyCachedURLResponse: NSObject, NSSecureCoding {

    public static var supportsSecureCoding: Bool { return true }

    private (set) var response: URLResponse
    private (set) var data: Data
    private (set) var storagePolicy: URLCache.StoragePolicy = .allowed

    public init(response: URLResponse, data: Data) {
        self.response = response.copy() as! URLResponse
        self.data = data
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(response, forKey: "response")
        aCoder.encode(NSData(data: data), forKey: "data")
        aCoder.encode(storagePolicy.rawValue, forKey: "storagePolicy")
    }

    public required init?(coder aDecoder: NSCoder) {
        guard
            let response = aDecoder.decodeObject(of: URLResponse.self, forKey: "response"),
            let data = aDecoder.decodeObject(of: NSData.self, forKey: "data"),
            let storagePolicy = URLCache.StoragePolicy(rawValue: UInt(aDecoder.decodeInt64(forKey: "storagePolicy")))
        else { return nil }

        self.response = response
        self.data = Data(referencing: data)
        self.storagePolicy = storagePolicy
    }
}
