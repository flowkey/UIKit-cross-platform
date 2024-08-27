//
//  CALayer+animations.swift
//  UIKit
//
//  Created by Michael Knoch on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CALayer {
    public func add(_ animation: CABasicAnimation, forKey keyPath: String) {
        let copy = CABasicAnimation(from: animation)
        copy.creationTime = Timer()

        // animation.fromValue is optional, set it to currently visible state if nil
        if copy.fromValue == nil, let keyPath = copy.keyPath {
            copy.fromValue = (_presentation ?? self).value(forKeyPath: keyPath)
        }

        copy.animationGroup?.queuedAnimations += 1

        animations[keyPath]?.animationGroup?.animationDidStop(finished: false)
        animations[keyPath] = copy
    }

    public func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    public func removeAllAnimations() {
        animations.removeAll()
    }

    func onWillSet(keyPath: AnimationKeyPath) {
        CALayer.layerTreeIsDirty = true
        let animationKey = keyPath.rawValue
        if let animation = action(forKey: animationKey) as? CABasicAnimation,
            self.hasBeenRenderedInThisPartOfOverallLayerHierarchy
                || animation.wasCreatedInUIAnimateBlock,
            !self.isPresentationForAnotherLayer,
            !CATransaction.disableActions()
        {
            add(animation, forKey: animationKey)
        }
    }

    func onDidSetAnimations(wasEmpty: Bool) {
        if !animations.isEmpty && wasEmpty {
            UIView.layersWithAnimations.insert(self)
            _presentation = createPresentation()

        } else if animations.isEmpty && !wasEmpty {
            _presentation = nil
            UIView.layersWithAnimations.remove(self)
        }
    }
}

extension CALayer {
    func animate(at currentTime: Timer) {
        let presentation = createPresentation()

        animations.forEach { (key, animation) in
            let animationProgress = animation.progress(for: currentTime)
            update(presentation, for: animation, with: animationProgress)

            if animationProgress == 1 && animation.isRemovedOnCompletion {
                animation.animationGroup?.animationDidStop(finished: true)
                removeAnimation(forKey: key)
            }
        }

        self._presentation = animations.isEmpty ? nil : presentation
    }

    private func update(_ presentation: CALayer, for animation: CABasicAnimation, with progress: CGFloat) {
        guard let keyPath = animation.keyPath else { return }

        switch keyPath {
        case .backgroundColor:
            guard let start = animation.fromValue as? UIColor else { return }
            let end = animation.toValue as? UIColor ?? self.backgroundColor ?? UIColor.clear
            presentation.backgroundColor = start.interpolation(to: end, progress: progress)

        case .position:
            guard let start = animation.fromValue as? CGPoint else { return }
            let end = animation.toValue as? CGPoint ?? self.position
            presentation.position = start + (end - start) * progress

        case .anchorPoint:
            guard let start = animation.fromValue as? CGPoint else { return }
            let end = animation.toValue as? CGPoint ?? self.anchorPoint
            presentation.anchorPoint = start + (end - start) * progress

        case .bounds:
            guard let startBounds = animation.fromValue as? CGRect else { return }
            let endBounds = animation.toValue as? CGRect ?? self.bounds
            presentation.bounds = (startBounds + (endBounds - startBounds) * progress)

        case .opacity:
            guard let startOpacity = animation.fromValue as? Float else { return }
            let endOpacity = animation.toValue as? Float ?? self.opacity
            presentation.opacity = startOpacity + ((endOpacity - startOpacity)) * Float(progress)

        case .transform:
            guard let startTransform = animation.fromValue as? CATransform3D else { return }
            let endTransform = animation.toValue as? CATransform3D ?? self.transform

            // Decompose the start and end transforms
            let startDecomposed = decompose(transform: startTransform)
            let endDecomposed = decompose(transform: endTransform)

            // Interpolate the decomposed components
            let interpolatedDecomposed = interpolate(
                start: startDecomposed,
                end: endDecomposed,
                progress: Float(progress)
            )

            // Recompose the interpolated transform
            let interpolatedTransform = recompose(transform: interpolatedDecomposed)

            // Apply the interpolated transform
            presentation.transform = interpolatedTransform

        case .unknown: break
        }
    }
}

extension CALayer {
    static let defaultAnimationDuration: CGFloat = 0.25

    static func defaultAction(forKey event: String) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: AnimationKeyPath(stringLiteral: event))
        animation.duration = CATransaction.animationDuration()
        return animation
    }
}

extension CALayer {
    func value(forKeyPath: AnimationKeyPath) -> AnimatableProperty? {
        switch forKeyPath as AnimationKeyPath  {
        case .backgroundColor: return backgroundColor
        case .opacity: return opacity
        case .bounds: return bounds
        case .transform: return transform
        case .position: return position
        case .anchorPoint: return anchorPoint
        case .unknown: return nil
        }
    }
}

private extension CABasicAnimation {
    var wasCreatedInUIAnimateBlock: Bool {
        return animationGroup != nil
    }
}

struct Quaternion {
    var x: Float
    var y: Float
    var z: Float
    var w: Float

    init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    init(transform: CATransform3D) {
        let m11 = transform.m11
        let m12 = transform.m12
        let m13 = transform.m13
        let m21 = transform.m21
        let m22 = transform.m22
        let m23 = transform.m23
        let m31 = transform.m31
        let m32 = transform.m32
        let m33 = transform.m33

        let trace = m11 + m22 + m33
        if trace > 0 {
            let s = sqrt(trace + 1.0) * 2
            self.w = 0.25 * s
            self.x = (m32 - m23) / s
            self.y = (m13 - m31) / s
            self.z = (m21 - m12) / s
        } else if (m11 > m22) && (m11 > m33) {
            let s = sqrt(1.0 + m11 - m22 - m33) * 2
            self.w = (m32 - m23) / s
            self.x = 0.25 * s
            self.y = (m12 + m21) / s
            self.z = (m13 + m31) / s
        } else if m22 > m33 {
            let s = sqrt(1.0 + m22 - m11 - m33) * 2
            self.w = (m13 - m31) / s
            self.x = (m12 + m21) / s
            self.y = 0.25 * s
            self.z = (m23 + m32) / s
        } else {
            let s = sqrt(1.0 + m33 - m11 - m22) * 2
            self.w = (m21 - m12) / s
            self.x = (m13 + m31) / s
            self.y = (m23 + m32) / s
            self.z = 0.25 * s
        }
    }

    func toTransform() -> CATransform3D {
        let x2 = x + x
        let y2 = y + y
        let z2 = z + z
        let xx = x * x2
        let xy = x * y2
        let xz = x * z2
        let yy = y * y2
        let yz = y * z2
        let zz = z * z2
        let wx = w * x2
        let wy = w * y2
        let wz = w * z2

        var transform = CATransform3DIdentity
        transform.m11 = 1.0 - (yy + zz)
        transform.m12 = xy - wz
        transform.m13 = xz + wy
        transform.m21 = xy + wz
        transform.m22 = 1.0 - (xx + zz)
        transform.m23 = yz - wx
        transform.m31 = xz - wy
        transform.m32 = yz + wx
        transform.m33 = 1.0 - (xx + yy)

        return transform
    }
}

extension Quaternion {
    static func slerp(from q1: Quaternion, to q2: Quaternion, progress: Float) -> Quaternion {
        // Compute the cosine of the angle between the two quaternions
        var cosTheta = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w

        // If cosTheta < 0, the interpolation will take the long way around the sphere.
        // To fix this, one quaternion must be negated.
        var q2 = q2
        if cosTheta < 0.0 {
            q2 = Quaternion(x: -q2.x, y: -q2.y, z: -q2.z, w: -q2.w)
            cosTheta = -cosTheta
        }

        // If the quaternions are too close, use linear interpolation
        if cosTheta > 0.9995 {
            let result = Quaternion(
                x: q1.x + progress * (q2.x - q1.x),
                y: q1.y + progress * (q2.y - q1.y),
                z: q1.z + progress * (q2.z - q1.z),
                w: q1.w + progress * (q2.w - q1.w)
            )
            return normalize(result)
        }

        // Perform the slerp interpolation
        let angle = acos(cosTheta)
        let sinTheta = sqrt(1.0 - cosTheta * cosTheta)
        let a = sin((1.0 - progress) * angle) / sinTheta
        let b = sin(progress * angle) / sinTheta

        return Quaternion(
            x: a * q1.x + b * q2.x,
            y: a * q1.y + b * q2.y,
            z: a * q1.z + b * q2.z,
            w: a * q1.w + b * q2.w
        )
    }

    static func normalize(_ q: Quaternion) -> Quaternion {
        let magnitude = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
        return Quaternion(x: q.x / magnitude, y: q.y / magnitude, z: q.z / magnitude, w: q.w / magnitude)
    }
}

struct DecomposedTransform {
    var scale: (x: Float, y: Float, z: Float)
    var translation: (x: Float, y: Float, z: Float)
    var rotation: Quaternion
}

#if os(Android)
private func sqrt(_ value: Float) -> Float {
    return Float(sqrt(Double(value)))
}
private func acos(_ value: Float) -> Float {
    return Float(acos(Double(value)))
}
private func sin(_ value: Float) -> Float {
    return Float(sin(Double(value)))
}
#endif

func decompose(transform: CATransform3D) -> DecomposedTransform {
    // Extract scale
    let scaleX = sqrt(transform.m11 * transform.m11 + transform.m12 * transform.m12 + transform.m13 * transform.m13)
    let scaleY = sqrt(transform.m21 * transform.m21 + transform.m22 * transform.m22 + transform.m23 * transform.m23)
    let scaleZ = sqrt(transform.m31 * transform.m31 + transform.m32 * transform.m32 + transform.m33 * transform.m33)

    // Normalize the rotation matrix
    var rotationMatrix = CATransform3DIdentity
    rotationMatrix.m11 = transform.m11 / scaleX
    rotationMatrix.m12 = transform.m12 / scaleX
    rotationMatrix.m13 = transform.m13 / scaleX
    rotationMatrix.m21 = transform.m21 / scaleY
    rotationMatrix.m22 = transform.m22 / scaleY
    rotationMatrix.m23 = transform.m23 / scaleY
    rotationMatrix.m31 = transform.m31 / scaleZ
    rotationMatrix.m32 = transform.m32 / scaleZ
    rotationMatrix.m33 = transform.m33 / scaleZ

    // Extract translation
    let translationX = transform.m41
    let translationY = transform.m42
    let translationZ = transform.m43

    // Convert rotation matrix to quaternion
    let quaternion = Quaternion(transform: rotationMatrix)

    return DecomposedTransform(
        scale: (x: scaleX, y: scaleY, z: scaleZ),
        translation: (x: translationX, y: translationY, z: translationZ),
        rotation: quaternion
    )
}


func interpolate(start: DecomposedTransform, end: DecomposedTransform, progress: Float) -> DecomposedTransform {
    let interpolatedScale = (
        x: start.scale.x + (end.scale.x - start.scale.x) * progress,
        y: start.scale.y + (end.scale.y - start.scale.y) * progress,
        z: start.scale.z + (end.scale.z - start.scale.z) * progress
    )

    let interpolatedTranslation = (
        x: start.translation.x + (end.translation.x - start.translation.x) * progress,
        y: start.translation.y + (end.translation.y - start.translation.y) * progress,
        z: start.translation.z + (end.translation.z - start.translation.z) * progress
    )

    let interpolatedRotation = Quaternion.slerp(
        from: start.rotation,
        to: end.rotation,
        progress: Float(progress)
    )

    return DecomposedTransform(
        scale: interpolatedScale,
        translation: interpolatedTranslation,
        rotation: interpolatedRotation
    )
}

func recompose(transform: DecomposedTransform) -> CATransform3D {
    // Create scale matrix
    var scaleMatrix = CATransform3DIdentity
    scaleMatrix.m11 = transform.scale.x
    scaleMatrix.m22 = transform.scale.y
    scaleMatrix.m33 = transform.scale.z

    // Create translation matrix
    var translationMatrix = CATransform3DIdentity
    translationMatrix.m41 = transform.translation.x
    translationMatrix.m42 = transform.translation.y
    translationMatrix.m43 = transform.translation.z

    // Convert quaternion to rotation matrix
    let rotationMatrix = transform.rotation.toTransform()

    // Combine all matrices
    var resultTransform = CATransform3DIdentity
    resultTransform = CATransform3DConcat(scaleMatrix, rotationMatrix)
    resultTransform = CATransform3DConcat(resultTransform, translationMatrix)

    return resultTransform
}
