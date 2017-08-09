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
            self.frame.width = CGFloat(image.size.width)
            self.frame.height = CGFloat(image.size.height)
            updateTextureFromImage()
        }
        
        isUserInteractionEnabled = false
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    private func updateTextureFromImage() {
        guard let image = image else { return }
        layer.texture = image.texture
    }

    public var image: UIImage? {
        didSet { updateTextureFromImage() }
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let image = image else { return .zero }
        return CGSize(width: image.size.width, height: image.size.height)
    }

    open var contentMode: UIContentMode = .stretch // XXX: Not sure this is true. In any case it's not implemented yet.
}

public enum UIContentMode {
    case left, right, top, bottom
    case center, stretch, contain
    case scaleAspectFit
}
