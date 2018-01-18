//
//  AVPlayerLayer+Mac.swift
//  UIKit
//
//  Created by Geordie Jay on 17.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import AVFoundation
import var SDL_gpu.GPU_FORMAT_RGBA

public final class AVPlayerLayer: CALayer {
    public convenience init(player: AVPlayer? = nil) {
        self.init()
        self.player = player
        addDisplayLinkIfNeeded()
    }

    public var player: AVPlayer? {
        didSet { addDisplayLinkIfNeeded() }
    }

    private let displayLink = DisplayLink()
    private func addDisplayLinkIfNeeded() {
        displayLink.callback = updateVideoFrame
        displayLink.isPaused = false
    }

    private var playerOutput = AVPlayerItemVideoOutput()

    open override var frame: CGRect {
        didSet {
            if frame.size == .zero || frame.size == oldValue.size { return }

            player?.currentItem?.remove(playerOutput)

            playerOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferOpenGLCompatibilityKey as String: true,
                kCVPixelBufferWidthKey as String: 1920 / 2,
                kCVPixelBufferHeightKey as String: 650 / 2
            ])

            playerOutput.suppressesPlayerRendering = true
            player?.currentItem?.add(playerOutput)
        }
    }

    func updateVideoFrame() {
        guard
            let playerItem = player?.currentItem,
            playerItem.status == .readyToPlay,
            playerOutput.hasNewPixelBuffer(forItemTime: playerItem.currentTime()),
            let pixelBuffer = playerOutput.copyPixelBuffer(forItemTime: playerItem.currentTime(), itemTimeForDisplay: nil)
            else { return }

        do    { CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)!
        let pixelBytes = pixelData.assumingMemoryBound(to: UInt8.self)

        if texture?.size != CGSize(width: width, height: height) {
            texture = VideoTexture(width: width, height: height, format: GPU_FORMAT_RGBA)
        }

        // Swap R and B values to get RGBA pixels instead of BGRA:
        for i in stride(from: 0, to: CVPixelBufferGetDataSize(pixelBuffer), by: 4) {
            swap(&pixelBytes[i], &pixelBytes[i + 2])
        }

        texture!.replacePixels(with: pixelBytes, bytesPerPixel: 4)
    }
}
