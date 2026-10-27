#if os(Android)
public struct NSNumber: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    internal enum Storage {
        case int(Int)
        case double(Double)
    }

    internal let storage: Storage

    public init(value: Int) {
        storage = .int(value)
    }

    public init(value: Double) {
        storage = .double(value)
    }

    public init(integerLiteral value: Int) {
        self.init(value: value)
    }

    public init(floatLiteral value: Double) {
        self.init(value: value)
    }

    public var doubleValue: Double {
        switch storage {
        case .int(let value): Double(value)
        case .double(let value): value
        }
    }
}
#endif
