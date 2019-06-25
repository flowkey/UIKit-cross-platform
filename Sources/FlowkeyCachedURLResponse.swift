//
//  FlowkeyCachedURLResponse.swift
//  UIKit
//
//  Created by Chetan Agarwal on 24/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

import Foundation

#if os(Android)
public typealias CachedURLResponse = FlowkeyCachedURLResponse
#endif

open class FlowkeyCachedURLResponse: NSObject, NSSecureCoding {

    public static var supportsSecureCoding: Bool { return true }

    var response: URLResponse
    var data: Data

    public init(response: URLResponse, data: Data) {
        self.response = response.copy() as! URLResponse
        self.data = data
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(response, forKey: "response")
        aCoder.encode(NSData(data: data), forKey: "data")
    }

    public required init?(coder aDecoder: NSCoder) {
        guard
            let response = aDecoder.decodeObject(of: URLResponse.self, forKey: "response"),
            let data = aDecoder.decodeObject(of: NSData.self, forKey: "data") else {
                return nil
        }
        self.response = response
        self.data = Data(referencing: data)
    }
}
