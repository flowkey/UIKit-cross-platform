private let frameSize = CGSize(width: 51, height: 31)
private let thumpSize = frameSize.height - 3
private let animationTime = 0.25

open class UISwitch: UIControl {

    public let tapGestureRecognizer = UITapGestureRecognizer()

    private var backgroundView = UIView()
    private var thumpView = UIView()

    public var onTintColor: UIColor? = .blue

    public var isOn = false {
        didSet {
            print("UISwitch isOn \(isOn)")
            backgroundView.backgroundColor = isOn ? onTintColor : .lightGray
            
            let newX = isOn
                ? frame.width - thumpView.frame.width - (frameSize.height - thumpSize) / 2
                : (frameSize.height - thumpSize) / 2
            
            UIView.animate(withDuration: animationTime) {
                thumpView.frame.origin.x = newX
            }
        }
    }

    public init() {
        super.init(
            frame: CGRect(origin: CGPoint(x: 0, y: 0), size: frameSize)
        )

        backgroundView.frame = frame
        backgroundView.backgroundColor = isOn ? onTintColor : .lightGray
        backgroundView.layer.cornerRadius = frame.height / 2
        addSubview(backgroundView)
        
        thumpView.frame.size = CGSize(width: thumpSize, height: thumpSize)
        thumpView.frame.midY = frame.midY
        thumpView.frame.origin.x = (frameSize.height - thumpSize) / 2
        thumpView.layer.cornerRadius = thumpSize / 2
        thumpView.backgroundColor = .white
        addSubview(thumpView)

        tapGestureRecognizer.view = self
        tapGestureRecognizer.onPress = {
            self.isOn.toggle()
            self.onPress?(self.isOn)
        }
        addGestureRecognizer(tapGestureRecognizer)
    }

    public var onPress: ((Bool) -> Void)?

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.frame.size
    }

}
