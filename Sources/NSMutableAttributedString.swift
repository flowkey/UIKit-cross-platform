//
//  NSMutableAttributedString.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// TODO: add further API for attributes

public class NSMutableAttributedString: NSAttributedString  {
    public init() {
        super.init(string: "")
    }

    public override init(string: String) {
        super.init(string: string)
    }

    public var length: Int {
        return string.characters.count
    }

    public func append(_ attributedString: NSAttributedString) {
        self.string = self.string + attributedString.string
    }

    public func addAttributes(_ attrs: [String: Any], range: NSRange) {
        // to be implemented
    }
}
