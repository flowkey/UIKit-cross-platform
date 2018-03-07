import Foundation

class VelocityTracker {

    private let bufferSize: Int
    private var velocityBuffer: [CGPoint]

    var mean: CGPoint { return velocityBuffer.mean() }
    var median: CGPoint { return velocityBuffer.median() }
    var last: CGPoint { return velocityBuffer.last ?? .zero } // return .zero if none exists

    init(bufferSize: Int) {
        self.bufferSize = bufferSize
        self.velocityBuffer = [CGPoint](repeating: .zero, count: bufferSize)
    }

    func track(timeInterval: TimeInterval, previousPoint: CGPoint, currentPoint: CGPoint) {
        track(
            timeInterval: timeInterval,
            translation: currentPoint - previousPoint
        )
    }

    func track(timeInterval: TimeInterval, translation: CGPoint) {
        velocityBuffer.removeFirst()
        velocityBuffer.append(calculateVelocity(timeInterval, translation))
    }

    func reset() {
        velocityBuffer = [CGPoint](repeating: .zero, count: bufferSize)
    }

    private func calculateVelocity(_ timeInterval: TimeInterval, _ translation: CGPoint) -> CGPoint {
        if timeInterval == 0 { return .zero }
        return translation / CGFloat(timeInterval)
    }

}


private extension Array where Element == CGPoint {
    func mean() -> CGPoint {
        return self.reduce(.zero, +) / CGFloat(self.count)
    }
    func median() -> CGPoint {
        let sorted = self.sorted{ $0.normLength < $1.normLength }
        if sorted.count % 2 == 0 {
            let midIndex = (sorted.count / 2)
            return (sorted[midIndex] + sorted[midIndex - 1]) / 2
        } else {
            return sorted[(sorted.count - 1) / 2]
        }
    }
}