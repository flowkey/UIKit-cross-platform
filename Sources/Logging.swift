//
//  Logging.swift
//  UIKit
//
//  Created by Geordie Jay on 07.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

#if os(Android)
import Glibc
#else
import Darwin.C.stdio
#endif

private let loggingTag = "NativePlayer"

@discardableResult
@_silgen_name("__android_log_write")
func android_log_write(_ prio: Int32, _ tag: UnsafePointer<CChar>, _ text: UnsafePointer<CChar>) -> Int32

// Replace `Swift.print` on Android (because the built-in one doesn't work there)
public func print(_ items: Any...) {
    log(items, priority: .info)
}

private var thread = pthread_t()

public class NativeLogRedirector {
    public init?() {

        // Spawn the logging thread
//        if pthread_create(&thread, nil, { ptr -> UnsafeMutableRawPointer? in
//            android_log_write(LogPriority.info.rawValue, loggingTag, "Logging thread started");
//            // create the pipe and redirect stdout and stderr
//            let pipeFileDescriptor = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
//            pipe(pipeFileDescriptor)
//            dup2(pipeFileDescriptor[1], STDOUT_FILENO)
//            dup2(pipeFileDescriptor[1], STDERR_FILENO)
//
//            let inputFile = fdopen(pipeFileDescriptor[0], "r")
//            let bufferCount = 256
//            var buffer = [Int8](repeating: 0, count: bufferCount)
//
//            while true {
//                fgets(&buffer, Int32(bufferCount), inputFile)
//                android_log_write(LogPriority.info.rawValue, loggingTag, buffer)
//            }
//
//            android_log_write(LogPriority.info.rawValue, loggingTag, "End logging thread")
//            pipeFileDescriptor.deallocate(capacity: 2)
//
//            return nil
//        }, nil) == -1 {
//            android_log_write(LogPriority.info.rawValue, loggingTag, "Couldnt create thread")
//            return nil
//        }
//
//        pthread_detach(thread)
//        android_log_write(LogPriority.info.rawValue, loggingTag, "Created logger")
    }

    deinit {
        //pthread_cancel(thread)
    }
}


// Only use this on Android! It's private because the API is incompatible with `Swift.print`.
// We don't want `log(xyz, .priority)` anywhere in cross-platform code!
private func log(_ items: Any..., priority: LogPriority) {
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
    log("\(file): \(line)\n" + message(), priority: .error)
    Swift.fatalError(message, file: file, line: line)
}

public enum LogPriority: Int32 {
    case `unknown`,`default`,`verbose`,`debug`,`info`,`warn`,`error`,`fatal`,`silent`
}
