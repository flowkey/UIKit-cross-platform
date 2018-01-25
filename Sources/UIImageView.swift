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

        if let image = image {
            updateTextureFromImage()
            self.frame.size = image.size
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    private func updateTextureFromImage() {
        layer.contents = image?.cgImage
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

        switch contentMode {
        case .center:
            layer.frame = CGRect(
                origin: CGPoint(
                    x: (bounds.width - image.size.width) / 2,
                    y: (bounds.height - image.size.height) / 2),
                size: image.size
            )

        case .scaleAspectFit:
            let scaleX = bounds.width / image.size.width
            let scaleY = bounds.height / image.size.height
            let minScale = min(scaleX, scaleY)
            layer.transform = CGAffineTransform(scale: minScale)

        case .stretch:
            let scaleX = bounds.width / image.size.width
            let scaleY = bounds.height / image.size.height
            layer.transform = CGAffineTransform(scaleByX: scaleX, byY: scaleY)

        default: break
        }
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let image = image else { return .zero }
        return CGSize(width: image.size.width, height: image.size.height)
    }

    open var contentMode: UIContentMode = .stretch
}

public enum UIContentMode {
    case left, right, top, bottom
    case center, stretch, contain
    case scaleAspectFit
}
