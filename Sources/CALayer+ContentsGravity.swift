/*
 * Apples CALayerContentsGravity implementation is based on a struct
 * with a raw representable because of backwards compatibility
 * We implemented it with an enum, which can be used the
 * same way as Apples CALayerContentsGravity
*/
public enum CALayerContentsGravity {
    case bottom, bottomLeft, bottomRight
    case center, left, right
    case top, topLeft, topRight
    case resize, resizeAspect, resizeAspectFill
}

struct ContentsGravityTransformation {
    /// `offset` is in the provided `layer`'s own (`bounds`) coordinates
    let offset: CGPoint

    /// `scale` is a proportion by which the `layer` will be transformed in each `width` and `height`
    let scale: CGSize

    /// Warning, this assumes `layer` has `contents` and will crash otherwise!
    init(for layer: CALayer) {
        let scaledContents = CGSize(
            width: CGFloat(layer.contents!.width) / layer.contentsScale,
            height: CGFloat(layer.contents!.height) / layer.contentsScale
        )

        let bounds = layer.bounds
        var distanceToMinX: CGFloat {
            return -((bounds.width - scaledContents.width) * layer.anchorPoint.x)
        }
        var distanceToMinY: CGFloat {
            return -((bounds.height - scaledContents.height) * layer.anchorPoint.y)
        }
        var distanceToMaxX: CGFloat {
            return (bounds.width - scaledContents.width) * (1 - layer.anchorPoint.x)
        }
        var distanceToMaxY: CGFloat {
            return (bounds.height - scaledContents.height) * (1 - layer.anchorPoint.y)
        }

        switch layer.contentsGravity {
        case .resize:
            offset = .zero
            scale = CGSize(width: bounds.width / scaledContents.width, height: bounds.height / scaledContents.height)
        case .resizeAspectFill:
            offset = .zero
            let maxScale = max(bounds.width / scaledContents.width, bounds.height / scaledContents.height)
            scale = CGSize(width: maxScale, height: maxScale)
        case .resizeAspect:
            offset = .zero
            let minScale = min(bounds.width / scaledContents.width, bounds.height / scaledContents.height)
            scale = CGSize(width: minScale, height: minScale)
        case .center:
            offset = .zero
            scale = .defaultScale
        case .left:
            offset = CGPoint(x: distanceToMinX, y: 0.0)
            scale = .defaultScale
        case .right:
            offset = CGPoint(x: distanceToMaxX, y: 0.0)
            scale = .defaultScale
        case .top:
            offset = CGPoint(x: 0.0, y: distanceToMinY)
            scale = .defaultScale
        case .bottom:
            offset = CGPoint(x: 0.0, y: distanceToMaxY)
            scale = .defaultScale
        case .topLeft:
            offset = CGPoint(x: distanceToMinX, y: distanceToMinY)
            scale = .defaultScale
        case .topRight:
            offset = CGPoint(x: distanceToMaxX, y: distanceToMinY)
            scale = .defaultScale
        case .bottomLeft:
            offset = CGPoint(x: distanceToMinX, y: distanceToMaxY)
            scale = .defaultScale
        case .bottomRight:
            offset = CGPoint(x: distanceToMaxX, y: distanceToMaxY)
            scale = .defaultScale
        }
    }
}

private extension CGSize {
    static let defaultScale = CGSize(width: 1.0, height: 1.0)
}
