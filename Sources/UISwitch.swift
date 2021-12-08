private let frameSize = CGSize(width: 51, height: 31)
private let thumpSize = frameSize.height - 3
private let animationTime = 0.25

open class UISwitch: UIControl {

    public let tapGestureRecognizer = UITapGestureRecognizer()

    private var thumb = UIView()

    public var onTintColor: UIColor? = .blue

    public var thumbTintColor: UIColor? {
        set { thumb.backgroundColor = newValue }
        get { thumb.backgroundColor }
    }

    public var isOn = false {
        didSet {
            let newX = isOn
                ? frame.width - thumb.frame.width - (frameSize.height - thumpSize) / 2
                : (frameSize.height - thumpSize) / 2
            
            UIView.animate(withDuration: animationTime) {
                thumb.frame.origin.x = newX
                backgroundColor = isOn ? onTintColor : .lightGray
            }
        }
    }

    public init() {
        super.init(
            frame: CGRect(origin: CGPoint(x: 0, y: 0), size: frameSize)
        )

        backgroundColor = isOn ? onTintColor : .lightGray
        layer.cornerRadius = frame.height / 2
        
        thumb.frame.size = CGSize(width: thumpSize, height: thumpSize)
        thumb.frame.midY = frame.midY
        thumb.frame.origin.x = (frameSize.height - thumpSize) / 2
        thumb.layer.cornerRadius = thumpSize / 2
        thumb.backgroundColor = .white
        addSubview(thumb)

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
