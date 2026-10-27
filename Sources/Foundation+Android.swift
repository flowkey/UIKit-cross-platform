#if os(Android)
public final class NSNumber: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let doubleValue: Double

    public init(value: Double) {
        doubleValue = value
    }

    public convenience init(floatLiteral value: Double) {
        self.init(value: value)
    }

    public convenience init(integerLiteral value: Int) {
        self.init(value: Double(value))
    }
}
#endif
