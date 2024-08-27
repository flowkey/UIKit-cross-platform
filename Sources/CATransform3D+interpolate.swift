func interpolate(
    startTransform: CATransform3D,
    endTransform: CATransform3D,
    progress: Float
) -> CATransform3D {

    let start = decompose(transform: startTransform)
    let end = decompose(transform: endTransform)

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

    let interpolatedDecomposedTransform = DecomposedTransform(
        scale: interpolatedScale,
        translation: interpolatedTranslation,
        rotation: interpolatedRotation
    )

    return interpolatedDecomposedTransform.recompose()
}

private struct DecomposedTransform {
    var scale: (x: Float, y: Float, z: Float)
    var translation: (x: Float, y: Float, z: Float)
    var rotation: Quaternion
}

private func decompose(transform: CATransform3D) -> DecomposedTransform {
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

private struct Quaternion {
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

private extension DecomposedTransform {
    func recompose() -> CATransform3D {
        let transform = self

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
