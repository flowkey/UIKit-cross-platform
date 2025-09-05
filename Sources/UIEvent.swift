@MainActor
public class UIEvent {
    internal static var activeEvents = Set<UIEvent>()

    public var allTouches: Set<UITouch>?
    public let timestamp = Timer().startTimeInMilliseconds

    public init() {}

    internal init(touch: UITouch) {
        allTouches = Set<UITouch>([touch])
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
