//
//  Logging.swift
//  UIKit
//
//  Created by Geordie Jay on 07.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

#if os(Android)
import Bionic
#else
import Darwin.C.stdio
#endif

private let loggingTag = "Swift"

@discardableResult
@_silgen_name("__android_log_write")
public func android_log_write(_ prio: Int32, _ tag: UnsafePointer<CChar>, _ text: UnsafePointer<CChar>) -> Int32

// Replace `Swift.print` on Android (because the built-in one doesn't work there)
public func print(_ items: Any...) {
    log(items, priority: .info)
}

// Only use this on Android! It's private because the API is incompatible with `Swift.print`.
// We don't want `log(xyz, .priority)` anywhere in cross-platform code!
private func log(_ items: [Any], priority: LogPriority) {
    let text = items.map { item in
        if let item = item as? CustomStringConvertible {
            return item.description
        } else {
            return String(reflecting: item)
        }
    }.joined(separator: " ")

    android_log_write(priority.rawValue, loggingTag, text)
}


public func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, _ flag: Bool = false) -> Never {
    log(["\(file): \(line)\n" + message()], priority: .error)
    Swift.fatalError(message(), file: file, line: line)
}

public enum LogPriority: Int32 {
    case `unknown`,`default`,`verbose`,`debug`,`info`,`warn`,`error`,`fatal`,`silent`
}
