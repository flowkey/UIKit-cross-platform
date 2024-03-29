open class UIActivityIndicatorView: UIView {
    public enum Style {
        case white
        case gray
        case medium
        case whiteLarge
    }

    private var timerTask: Task<Void, Never>?
    private var elements: [UIView] = []
    private var currentHighlightedElementIndex = 0

    private let numberOfElements = 8
    private let radius: CGFloat = 7.5
    private let elementWidth: CGFloat = 3
    private let elementHeight: CGFloat = 7
    private var elementCornerRadius: CGFloat {
        return elementWidth / 2
    }

    public init(style: Style) {
        print("UIActivityIndicatorView.Style \(style) was passed, but only one color style is supported.")
        
        let size: CGFloat = (radius + elementHeight / 2) * 2
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))

        elements = (0..<numberOfElements).map { i in
            let element = UIView(frame: CGRect(x: 0, y: 0, width: elementWidth, height: elementHeight))
            
            // calculate a point on a circle to use as origin
            let pointOnCircle = CGPoint(
                x: radius * cos((CGFloat(i) * 2 * .pi) / CGFloat(numberOfElements)),
                y: radius * sin((CGFloat(i) * 2 * .pi) / CGFloat(numberOfElements))
            )
            
            // assign origin & center in this view
            element.center.x = pointOnCircle.x + frame.width / 2
            element.center.y = pointOnCircle.y + frame.height / 2
            
            // rotate element
            let degreesToRotate: CGFloat = -90 + CGFloat((360 / numberOfElements) * i)
            element.transform = AffineTransform(rotationByDegrees: degreesToRotate)
            
            element.backgroundColor = shadesOfGrey.last
            element.layer.cornerRadius = elementCornerRadius

            return element
        }
        
        elements.forEach { addSubview($0) }
    }

    public func startAnimating() {
        startTimer()
    }

    private func startTimer() {
        guard timerTask == nil else { return }

        let updateIntervalInSeconds = 1 / Double(numberOfElements)

        timerTask = Task {
            while(!Task.isCancelled) {
                try? await Task.sleep(nanoseconds: UInt64(updateIntervalInSeconds * 1000 * 1000 * 1000))
                Task { @MainActor in self.updateColors() }
            }
        }
    }
    
    private func updateColors() {
        self.currentHighlightedElementIndex = (self.currentHighlightedElementIndex + 1) % self.numberOfElements
        self.elements.enumerated().forEach { i, element in
            element.backgroundColor = getElementColorForIndex(i)
        }
    }

    private func getElementColorForIndex(_ i: Int) -> UIColor? {
        if i == currentHighlightedElementIndex {
            return shadesOfGrey[0]
        } else if i == (currentHighlightedElementIndex - 1 + numberOfElements) % numberOfElements {
            return shadesOfGrey[1]
        } else if i == (currentHighlightedElementIndex - 2 + numberOfElements) % numberOfElements {
            return shadesOfGrey[2]
        } else if i == (currentHighlightedElementIndex - 3 + numberOfElements) % numberOfElements {
            return shadesOfGrey[3]
        } else {
            return shadesOfGrey.last
        }
    }

    public func stopAnimating() {
        timerTask?.cancel()
        timerTask = nil
    }
}

private let shadesOfGrey = [0.5, 0.55, 0.6, 0.65, 0.85].map {
    UIColor(red: $0, green: $0, blue: $0, alpha: 1)
}
