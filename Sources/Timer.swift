//
//  HighresTimer.swift
//  UIKit
//
//  Created by Geordie Jay on 07.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(Android)
import Bionic
#else
import Darwin.C
#endif

struct Timer {
    let startTime: timeval
    init(startingAt startingTimeInMilliseconds: Double = 0.0) {
        var startTime = timeval()
        gettimeofday(&startTime, nil)

        let seconds = (startingTimeInMilliseconds / 1000).rounded(.down)
        let milliseconds = startingTimeInMilliseconds.truncatingRemainder(dividingBy: 1000)
        startTime.tv_sec += type(of: startTime.tv_sec).init(seconds)
        startTime.tv_usec += type(of: startTime.tv_usec).init(milliseconds * 1000)

        self.startTime = startTime
    }

    var startTimeInMilliseconds: Double {
        startTime.inMilliseconds
    }

    var elapsedTimeInMilliseconds: Double {
        var currentTime = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&currentTime, nil)
        return max(0.001, currentTime.inMilliseconds - startTime.inMilliseconds)
    }

    var elapsedTimeInSeconds: Double {
        var currentTime = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&currentTime, nil)
        return max(0.000001, currentTime.inSeconds - startTime.inSeconds)
    }
}

private extension timeval {
    var inMilliseconds: Double {
        return (Double(self.tv_sec) * 1_000) + (Double(self.tv_usec) / 1_000)
    }

    var inSeconds: Double {
        return (Double(self.tv_sec) + Double(self.tv_usec) / 1_000_000)
    }
}

extension Timer {
    static func -(lhs: Timer, rhs: Timer) -> Double {
        return lhs.startTime.inMilliseconds - rhs.startTime.inMilliseconds
    }
}
