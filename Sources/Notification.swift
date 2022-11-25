public struct Notification {
    public let name: Name
    weak internal(set) public var object: AnyObject?

    internal init(name: Name, object: AnyObject? = nil) {
        self.name = name
        self.object = object
    }
}

extension Notification {
    public struct Name: Hashable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}
