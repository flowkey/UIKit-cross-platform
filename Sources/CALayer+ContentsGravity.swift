//
//  CALayer+ContentsGravity.swift
//  UIKit
//
//  Created by Geordie Jay on 18.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//


extension CALayer {
    internal enum ContentsGravity: String {
        case left, center, right, top, bottom
        case resize, resizeAspectFill, resizeAspectFit = "resizeAspect"
    }
}

struct ContentsGravityTransformation {
    /// `offset` is in the provided `layer`'s own (`bounds`) coordinates
    let offset: CGPoint

    /// `scale` is a proportion by which the `layer` will be transformed in each `width` and `height`
    let scale: CGSize

    /// Warning, this assumes `layer` has `contents` and will crash otherwise!
    init(for layer: CALayer) {
        let scaledContents = CGSize(
            width: layer.contents!.size.width / layer.contentsScale,
            height: layer.contents!.size.height / layer.contentsScale
        )

        let bounds = layer.bounds

        switch layer.contentsGravityEnum {
        case .resize:
            offset = .zero
            scale = CGSize(width: bounds.width / scaledContents.width, height: bounds.height / scaledContents.height)
        case .resizeAspectFill:
            offset = .zero
            let maxScale = max(bounds.width / scaledContents.width, bounds.height / scaledContents.height)
            scale = CGSize(width: maxScale, height: maxScale)
        case .resizeAspectFit:
            offset = .zero
            let minScale = min(bounds.width / scaledContents.width, bounds.height / scaledContents.height)
            scale = CGSize(width: minScale, height: minScale)
        case .center:
            offset = .zero
            scale = .defaultScale
        case .left:
            let distanceToMinX = -((bounds.width - scaledContents.width) * layer.anchorPoint.x)
            offset = CGPoint(x: distanceToMinX, y: 0.0)
            scale = .defaultScale
        case .right:
            let distanceToMaxX = bounds.width * (1 - layer.anchorPoint.x)
            offset = CGPoint(x: distanceToMaxX - scaledContents.width, y: 0.0)
            scale = .defaultScale
        case .top:
            let distanceToMinY = -((bounds.height - scaledContents.height) * layer.anchorPoint.y)
            offset = CGPoint(x: 0.0, y: distanceToMinY)
            scale = .defaultScale
        case .bottom:
            let distanceToMaxY = bounds.height * (1 - layer.anchorPoint.y)
            offset = CGPoint(x: 0.0, y: distanceToMaxY - scaledContents.height)
            scale = .defaultScale
        }
    }
}

private extension CGSize {
    static let defaultScale = CGSize(width: 1.0, height: 1.0)
}
