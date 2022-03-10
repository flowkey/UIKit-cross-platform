import Dispatch
import Foundation


// alias since we already have a Timer type in UIKit
typealias FTimer = Foundation.Timer

open class UIActivityIndicatorView: UIView {
    
    public enum Style {
        case white
        case gray
        case whiteLarge
    }

    private var timer: FTimer?
    private var elements: [UIView] = []
    private var currentHighlightedElementIndex = 0
    
    private let numberOfElements = 8
    private let radius: CGFloat = 7.5
    private let elementWidth: CGFloat = 3
    private let elementHeight: CGFloat = 7
    private let elementCornerRadius: CGFloat

    public init(style: Style) {
        print("UIActivityIndicatorView.Style \(style) was passed, but only one color scheme is supported.")

        self.elementCornerRadius = elementWidth / 2
        
        let size: CGFloat = (radius + elementHeight / 2) * 2
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))


        elements = (0..<numberOfElements).map { i in
            let element = UIView()
            element.frame.size = CGSize(width: elementWidth, height: elementHeight)
            
            // calculate a point on a circle to use as origin
            let pointOnCircle = CGPoint(
                x: radius * cos((CGFloat(i) * 2.0 * .pi) / CGFloat(numberOfElements)),
                y: radius * sin((CGFloat(i) * 2.0 * .pi) / CGFloat(numberOfElements))
            )
            
            // assign origin & center in this view
            element.center.x = pointOnCircle.x + frame.width / 2
            element.center.y = pointOnCircle.y + frame.height / 2
            
            // rotate element
            let degreesToRotate: CGFloat = -90 + CGFloat((360 / numberOfElements) * i)
            element.transform = AffineTransform(rotationByDegrees: degreesToRotate)
            
            element.backgroundColor = fiveShadesOfGrey.last
            element.layer.cornerRadius = elementCornerRadius

            return element
        }
        
        elements.forEach { addSubview($0) }
    }

    public func startAnimating() {
        #if os(macOS)
            if #available(macOS 10.12, *) {
                startTimer()
            }
        #else
            startTimer()
        #endif

    }

    @available(macOS 10.12, *) // also works for Android
    private func startTimer() {
        if self.timer?.isValid ?? false {
            return
        }
        self.timer = FTimer.scheduledTimer(withTimeInterval: 1/Double(numberOfElements), repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateColors()
            }
        }
    }
    
    private func updateColors() {
        self.currentHighlightedElementIndex = (self.currentHighlightedElementIndex + 1) % self.numberOfElements
        self.elements.enumerated().forEach { i, element in
            element.backgroundColor = getElementColorForIndex(i)
        }
    }

    private func getElementColorForIndex(_ i: Int) -> UIColor {
        if i == self.currentHighlightedElementIndex {
            return fiveShadesOfGrey[0]
        } else if i == (self.currentHighlightedElementIndex - 1 + self.numberOfElements) % self.numberOfElements {
            return fiveShadesOfGrey[1]
        } else if i == (self.currentHighlightedElementIndex - 2 + self.numberOfElements) % self.numberOfElements {
            return fiveShadesOfGrey[2]
        } else if i == (self.currentHighlightedElementIndex - 3 + self.numberOfElements) % self.numberOfElements {
            return fiveShadesOfGrey[3]
        } else {
            return fiveShadesOfGrey[4]
        }
    }

    public func stopAnimating() {
        timer?.invalidate()
    }
}

private let fiveShadesOfGrey = [0.5, 0.55, 0.6, 0.65, 0.85].map { CGColor(red: $0, green: $0, blue: $0, alpha: 1)}
