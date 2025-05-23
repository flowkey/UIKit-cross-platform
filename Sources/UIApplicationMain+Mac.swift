#if os(macOS)
//
//  UIApplication+Mac.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import CoreVideo

let displayID = CGMainDisplayID()
var displayLink: CVDisplayLink?

func setupRenderAndRunLoop() {
    if displayLink != nil {
        print("renderLoop already exists")
        return
    }

    CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink)
    let error = CVDisplayLinkCreateWithCGDisplay(displayID, &displayLink)

    guard let displayLink = displayLink, error == 0 else {
        fatalError("Couldn't create display link (error: \(error))")
    }

    CVDisplayLinkSetOutputCallback(displayLink, { (_, currentTime, presentationTime, _, _, userInfo) -> CVReturn in
        if presentationTime.pointee.hostTime > currentTime.pointee.hostTime {
            let currentTime = Timer()
            DispatchQueue.main.async {
                UIApplication.shared.handleEventsIfNeeded()
                UIScreen.main.render(window: UIApplication.shared.keyWindow, atTime: currentTime)
            }
         }

        return kCVReturnSuccess
    }, nil)

    DispatchQueue.main.async {
        CVDisplayLinkStart(displayLink)
    }

    RunLoop.current.run()
}
#endif
