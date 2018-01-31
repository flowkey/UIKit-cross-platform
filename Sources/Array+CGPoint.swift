extension Array where Element == CGPoint {
    func mean() -> CGPoint {
        return self.reduce(.zero, +) / CGFloat(self.count)
    }
}

private extension CGPoint {
    static func + (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + lhs.y)
    }
    static func / (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}