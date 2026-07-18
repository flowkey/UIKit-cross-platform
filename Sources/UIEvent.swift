@MainActor
public class UIEvent {
    internal static var activeEvents = Set<UIEvent>()

    public var allTouches: Set<UITouch>?

    /// The touch this delivery is about (the one that just began/moved/ended). `allTouches` still holds every
    /// finger currently down, so a multi-touch recognizer like pinch reads that; single-touch recognizers act
    /// on `changedTouch`.
    internal weak var changedTouch: UITouch?

    public let timestamp = Timer().startTimeInMilliseconds

    public init() {}

    internal init(touch: UITouch) {
        allTouches = Set<UITouch>([touch])
        changedTouch = touch
    }
}

extension UIEvent: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    nonisolated public static func ==(lhs: UIEvent, rhs: UIEvent) -> Bool {
        return lhs === rhs
    }
}
