//
//  AVPlayerLayer+Mac.swift
//  UIKit
//
//  Created by Geordie Jay on 17.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import AVFoundation
import var SDL_gpu.GPU_FORMAT_RGBA

public typealias AVPlayer = AVFoundation.AVPlayer

public enum AVLayerVideoGravity {
    case resizeAspectFill, resizeAspect, resize
}

public final class AVPlayerLayer: CALayer {
    public convenience init(player: AVPlayer? = nil) {
        self.init()
        self.player = player
        addDisplayLinkIfNeeded()
        updateContentsGravityFromVideoGravity()
    }

    public var player: AVPlayer? {
        didSet { addDisplayLinkIfNeeded() }
    }

    public var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet { updateContentsGravityFromVideoGravity() }
    }

    private func updateContentsGravityFromVideoGravity() {
        switch videoGravity {
        case .resize: contentsGravityEnum = .resize
        case .resizeAspect: contentsGravityEnum = .resizeAspectFit
        case .resizeAspectFill: contentsGravityEnum = .resizeAspectFill
        }
    }

    private let displayLink = DisplayLink()
    private func addDisplayLinkIfNeeded() {
        displayLink.callback = { [unowned self] in self.updateVideoFrame() }
        displayLink.isPaused = false
    }

    private var playerOutput = AVPlayerItemVideoOutput()

    open override var frame: CGRect {
        didSet {
            if frame.size == .zero { return }
            updatePlayerOutput(size: frame.size)
        }
    }

    var currentPlayerOutputSize: CGSize = .zero
    private func updatePlayerOutput(size: CGSize) {
        if size == currentPlayerOutputSize { return }

        guard
            let presentationSize = player?.currentItem?.presentationSize,
            presentationSize != .zero
        else {
            return
        }

        player?.currentItem?.remove(playerOutput)

        let aspectRatio = presentationSize.width / presentationSize.height
        
        
        let widthAlignedTo4PixelPadding = (size.width.remainder(dividingBy: 8) == 0) ?
            size.width : // <-- no padding required
            size.width + (8 - round(size.width).remainder(dividingBy: 8))

        
        playerOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferOpenGLCompatibilityKey as String: true,
            kCVPixelBufferWidthKey as String: widthAlignedTo4PixelPadding,
            kCVPixelBufferHeightKey as String: widthAlignedTo4PixelPadding / aspectRatio
        ])

        playerOutput.suppressesPlayerRendering = true
        player?.currentItem?.add(playerOutput)

        currentPlayerOutputSize = size
    }

    func updateVideoFrame() {
        updatePlayerOutput(size: frame.size)
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

        if contents?.width != width || contents?.height != height {
            contentsScale = 1.0 // this doesn't work on init because we set contentsScale in UIView.init afterwards
            contents = VideoTexture(width: width, height: height, format: GPU_FORMAT_RGBA)
        }

        // Swap R and B values to get RGBA pixels instead of BGRA:
        let bufferSize = CVPixelBufferGetDataSize(pixelBuffer)
        for i in stride(from: 0, to: bufferSize, by: 16) {
            swap(&pixelBytes[i], &pixelBytes[i + 2])
            swap(&pixelBytes[i+4], &pixelBytes[i + 6])
            swap(&pixelBytes[i+8], &pixelBytes[i + 10])
            swap(&pixelBytes[i+12], &pixelBytes[i + 14])
        }

        contents?.replacePixels(with: pixelBytes, bytesPerPixel: 4)
    }
}
