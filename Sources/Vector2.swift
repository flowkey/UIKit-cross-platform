import Foundation

typealias Vector2 = CGPoint

extension Vector2 {
    // norm a.k.a. absoluteValue of a Vector: https://en.wikipedia.org/wiki/Absolute_value#Vector_spaces
    var normLength: CGFloat {
        return sqrt(pow(self.x, 2) + pow(self.y, 2))
    }
}

