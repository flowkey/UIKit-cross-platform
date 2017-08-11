//
//  HighresTimer.swift
//  UIKit
//
//  Created by Geordie Jay on 07.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(Android)
import Glibc
#else
import Darwin.C
#endif

struct Timer {
    let startTime: timeval
    init(startingAt startingTimeInMilliseconds: Double = 0.0) {
        var startTime = timeval()
        gettimeofday(&startTime, nil)
        if !startingTimeInMilliseconds.isZero {
            startTime.tv_usec += type(of: startTime.tv_usec).init(startingTimeInMilliseconds * 1000)
        }
        self.startTime = startTime
    }

    func getElapsedTimeInMilliseconds() -> Double {
        var currentTime = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&currentTime, nil)
        return max(0.001, currentTime.inMilliseconds() - startTime.inMilliseconds())
    }
}

extension timeval {
    func inMilliseconds() -> Double {
        return (Double(self.tv_sec) * 1000) + (Double(self.tv_usec) / 1000)
    }
}

func sleepFor(milliseconds ms: Double) {
    if ms.isLessThanOrEqualTo(0.0) { return }
    let seconds = Int(ms / 1000) // "floor" value - e.g. 3.7 doesn't round up to 4, instead becomes 3!
    let remainingMilliseconds = ms.truncatingRemainder(dividingBy: 1000)
    var time = timespec(tv_sec: seconds, tv_nsec: Int(remainingMilliseconds * 1_000_000))
    nanosleep(&time, nil)
}

extension Timer {
    static func -(lhs: Timer, rhs: Timer) -> Double {
        return lhs.startTime.inMilliseconds() - rhs.startTime.inMilliseconds()
    }
}

