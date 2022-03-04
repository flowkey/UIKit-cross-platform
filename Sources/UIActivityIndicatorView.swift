//
//  UIActivityIndicatorView.swift
//  UIKit
//
//  Created by Chris on 09.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import Dispatch
import class Foundation.Timer

// alias since we already have a Timer type in UIKit
typealias FTimer = Foundation.Timer

public enum UIActivityIndicatorViewStyle {
    case whiteLarge
    case white
    case gray
}

open class UIActivityIndicatorView: UIView {
    public var activityIndicatorStyle: UIActivityIndicatorViewStyle

    let imageView = UIImageView()
    let images: [UIImage?]
    var currentImageIndex = 0
    var timer: FTimer?

    public init(style: UIActivityIndicatorViewStyle) {
        self.activityIndicatorStyle = style

        images = imagePaths.map { UIImage(named: $0) }
        imageView.image = images[0]
        imageView.contentMode = .scaleAspectFit

        super.init(frame: .zero)

        addSubview(imageView)
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return imageView.frame.size
    }

    public func startAnimating() {
        #if os(macOS)
            if #available(macOS 10.12, *) {
                startTimer()
            }
        #else
            startTimer()
        #endif

    }

    @available(macOS 10.12, *) // also works for Android
    private func startTimer() {
        if self.timer?.isValid ?? false {
            return
        }
        self.timer = FTimer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentImageIndex = (self.currentImageIndex + 1) % self.images.count
                self.imageView.image = self.images[self.currentImageIndex]
            }
        }
    }

    public func stopAnimating() {
        timer?.invalidate()
    }

}

private let imagePaths = [
    "loading_spinner_0.png",
    "loading_spinner_1.png",
    "loading_spinner_2.png",
    "loading_spinner_3.png",
    "loading_spinner_4.png",
    "loading_spinner_5.png",
    "loading_spinner_6.png",
    "loading_spinner_7.png",
    "loading_spinner_8.png",
    "loading_spinner_9.png",
    "loading_spinner_10.png",
    "loading_spinner_11.png",
    "loading_spinner_12.png",
    "loading_spinner_13.png",
    "loading_spinner_14.png",
    "loading_spinner_15.png",
    "loading_spinner_16.png",
    "loading_spinner_17.png",
    "loading_spinner_18.png",
    "loading_spinner_19.png",
    "loading_spinner_20.png",
    "loading_spinner_21.png",
    "loading_spinner_22.png",
    "loading_spinner_23.png",
    "loading_spinner_24.png",
    "loading_spinner_25.png",
    "loading_spinner_26.png",
    "loading_spinner_27.png",
    "loading_spinner_28.png",
    "loading_spinner_29.png",
]
