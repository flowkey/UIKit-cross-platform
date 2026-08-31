public class CAAnimationGroup: CABasicAnimation {
    public var animations: [CABasicAnimation]?

    public override init() {
        super.init()
    }

    init(from animation: CAAnimationGroup) {
        animations = animation.animations
        super.init(from: animation)
    }

    override func copy() -> CAAnimationGroup {
        return CAAnimationGroup(from: self)
    }

    func groupedAnimations() -> [CABasicAnimation] {
        return (animations ?? []).map { animation in
            let copy = animation.copy()
            copy.delay += delay
            copy.isRemovedOnCompletion = isRemovedOnCompletion
            if duration > 0 {
                copy.duration = min(copy.duration, duration)
            }
            return copy
        }
    }
}
