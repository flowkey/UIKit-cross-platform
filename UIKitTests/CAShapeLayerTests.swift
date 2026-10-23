import XCTest
@testable import UIKit

@MainActor
class CAShapeLayerTests: XCTestCase {
    private func dashes(_ pattern: [NSNumber], phase: CGFloat = 0) -> [ClosedRange<CGFloat>] {
        let layer = UIKit.CAShapeLayer()
        layer.lineDashPattern = pattern
        layer.lineDashPhase = phase
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 8, y: 0))
        return layer.dashedSegments(of: path.cgPath).map { $0.from.x ... $0.to.x }
    }

    func testDashPatternAlternatesDashesAndGaps() {
        XCTAssertEqual(dashes([3, 1]), [0...3, 4...7])
    }

    func testOddDashPatternRepeatsWithDashesAndGapsSwapped() {
        XCTAssertEqual(dashes([2]), [0...2, 4...6])
    }

    func testDashPhaseOffsetsThePattern() {
        XCTAssertEqual(dashes([2, 2], phase: 1), [0...1, 3...5, 7...8])
    }

    func testAddLineWithoutACurrentPointDoesNothing() {
        let path = UIBezierPath()
        path.addLine(to: CGPoint(x: 1, y: 1))
        XCTAssertTrue(path.cgPath.subpaths.isEmpty)
    }

    func testAddLineAfterCloseStartsFromTheSubpathsStart() {
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 4, y: 0))
        path.close()
        path.addLine(to: CGPoint(x: 0, y: 4))
        XCTAssertEqual(path.cgPath.subpaths.map(\.points), [[.zero, CGPoint(x: 4, y: 0)], [.zero, CGPoint(x: 0, y: 4)]])
    }

    func testPresentationKeepsTheShape() {
        let layer = UIKit.CAShapeLayer()
        layer.strokeColor = .red
        layer.lineDashPattern = [2, 2]

        let presentation = layer.createPresentation() as? UIKit.CAShapeLayer

        XCTAssertEqual(presentation?.strokeColor, .red)
        XCTAssertEqual(presentation?.lineDashPattern?.map(\.doubleValue), [2, 2])
    }

    func testImplicitActionUsesTheTransactionsTimingFunction() {
        let timing = UIKit.CAMediaTimingFunction(name: .easeIn)
        UIKit.CATransaction.begin()
        UIKit.CATransaction.setAnimationTimingFunction(timing)
        let action = UIKit.CALayer.defaultAction(forKey: "opacity")
        UIKit.CATransaction.commit()

        XCTAssert(action.timingFunction === timing)
    }
}

@MainActor
class UIViewWillMoveToSuperviewTests: XCTestCase {
    private final class RecordingView: UIView {
        var calls: [(newSuperview: UIView?, superview: UIView?, superlayer: UIKit.CALayer?)] = []
        override func willMove(toSuperview newSuperview: UIView?) {
            calls.append((newSuperview, superview, layer.superlayer))
        }
    }

    func testWillMoveIsCalledOncePerMoveBeforeTheViewMoves() {
        let firstSuperview = UIView(), secondSuperview = UIView(), view = RecordingView()

        firstSuperview.addSubview(view)
        secondSuperview.addSubview(view)
        view.removeFromSuperview()

        XCTAssertEqual(view.calls.count, 3)
        XCTAssert(view.calls[0].newSuperview === firstSuperview && view.calls[0].superlayer == nil)
        XCTAssert(view.calls[1].newSuperview === secondSuperview && view.calls[1].superview === firstSuperview)
        XCTAssert(view.calls[2].newSuperview == nil && view.calls[2].superlayer === secondSuperview.layer)
    }
}
