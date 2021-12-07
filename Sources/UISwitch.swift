open class UISwitch: UIControl {

    public let tapGestureRecognizer = UITapGestureRecognizer()

    private var backgroundView = UIView()

    public var onTintColor: UIColor?

    public var isOn = false {
        didSet {
            print("UISwitch isOn \(isOn)")
            backgroundView.backgroundColor = isOn ? onTintColor : .lightGray
        }
    }

    public init() {
        super.init(
            frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 51, height: 31))
        )

        backgroundView.frame = frame
        backgroundView.backgroundColor = isOn ? onTintColor : .lightGray
        addSubview(backgroundView)

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
