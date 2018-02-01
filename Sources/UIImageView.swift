//
//  UIImageView.swift
//  UIKit
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIImageView: UIView {
    public init(image: UIImage? = nil) {
        self.image = image
        super.init(frame: .zero)
        updateTextureFromImage()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    private func updateTextureFromImage() {
        layer.contents = image?.cgImage
        layer.contentsScale = image?.scale ?? UIScreen.main.scale
        if let image = image {
            bounds.size = image.size / image.scale
        }
    }

    public var image: UIImage? {
        didSet {
            updateTextureFromImage()
            setNeedsLayout()
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let image = image else { return }
        let scaledImageSize = image.size / image.scale

        switch contentMode {
        case .center:
            layer.frame = CGRect(
                origin: CGPoint(
                    x: (bounds.width - scaledImageSize.width) / 2,
                    y: (bounds.height - scaledImageSize.height) / 2),
                size: scaledImageSize
            )

        case .scaleAspectFit:
            let scaleX = bounds.width / scaledImageSize.width
            let scaleY = bounds.height / scaledImageSize.height
            let minScale = min(scaleX, scaleY)
            transform = CGAffineTransform(scale: minScale)

        case .stretch:
            let scaleX = bounds.width / scaledImageSize.width
            let scaleY = bounds.height / scaledImageSize.height
            transform = CGAffineTransform(scaleByX: scaleX, byY: scaleY)

        default: break
        }
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let image = image else { return .zero }
        return image.size / image.scale
    }

    open var contentMode: UIContentMode = .stretch
}

public enum UIContentMode {
    case left, right, top, bottom
    case center, stretch, contain
    case scaleAspectFit
}
