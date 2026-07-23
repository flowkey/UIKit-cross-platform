#if os(Android)
public typealias URL = String

extension String {
    public init(fileURLWithPath path: String) { self = path }
}
#endif
