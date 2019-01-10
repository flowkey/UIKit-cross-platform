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
            bounds.size = image.size
        }
    }

    public var image: UIImage? {
        didSet {
            if image === oldValue { return }
            updateTextureFromImage()
            setNeedsLayout()
        }
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return image?.size ?? .zero
    }

    open var contentMode: UIContentMode = .scaleToFill {
        didSet {
            switch contentMode {
            case .scaleToFill:
                layer.contentsGravity = .resize
            case .scaleAspectFill:
                layer.contentsGravity = .resizeAspectFill
            case .scaleAspectFit:
                layer.contentsGravity = .resizeAspect
            case .center:
                layer.contentsGravity = .center
            default:
                assertionFailure("The contentMode you tried to set (\(contentMode)) hasn't been implemented yet!")
            }
        }
    }
}

public enum UIContentMode {
    case left, right, top, bottom // Not implemented!
    case center
    case scaleToFill // resize / stretch
    case scaleAspectFit, scaleAspectFill
}
