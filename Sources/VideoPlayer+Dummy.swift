//
//  VideoPlayer.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class VideoPlayer: UIView {
    private let timer = VideoTimer()

    public init(url: String) {
        super.init(frame: .zero)
    }

    open func play() {
        // Java Video call here
        timer.start()
    }

    open func pause() {
        // Java Video call here
        timer.pause()
    }

    public func getCurrentTime() -> Double {
        return timer.getCurrentTime()
    }

    public func seek(to newTime: Double) {
        timer.update(to: newTime)
    }

    open var isMuted: Bool = false
    open var rate: Double = 1
}

private class VideoTimer {
    var timeWhenLastPaused: Double = 0.0 // milliseconds
    var runningTimer: Timer?

    func start() {
        guard runningTimer == nil else { return }
        runningTimer = Timer(startingAt: -timeWhenLastPaused)
    }

    func pause() {
        guard let runningTimer = runningTimer else { return }
        timeWhenLastPaused = Double(runningTimer.getElapsedTimeInMilliseconds())
        self.runningTimer = nil
    }

    /// Current clock time in milliseconds
    func getCurrentTime() -> Double {
        guard let runningTimer = runningTimer else { return timeWhenLastPaused / 1000 }
        return round(Double(runningTimer.getElapsedTimeInMilliseconds()))
    }

    func update(to videoTime: Double) { // videoTime is in milliseconds
        timeWhenLastPaused = videoTime
    }
}
