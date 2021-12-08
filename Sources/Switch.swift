private let frameSize = CGSize(width: 51, height: 21)
private let thumbSize = CGFloat(31.0)
private let animationTime = 0.25

private let defaultOnTintColor = CGColor(red: 0.69, green: 0.5, blue: 0.96, alpha: 1)
private let defaultThumbColor = CGColor(red: 0.30, green: 0, blue: 0.91, alpha: 1)

// Note: we deliberately don't wrap UISwitch.
// This allows us to have a somewhat custom API free of objc selectors etc.

open class Switch: UIControl {
    private let tapGestureRecognizer = UITapGestureRecognizer()
    
    private var thumb = UIView()

    public var onTintColor: UIColor? = defaultOnTintColor
    public var thumbTintColor: UIColor? = defaultThumbColor

    public var onPress: ((Bool) -> Void)?

    public var isOn = false {
        didSet {
            UIView.animate(withDuration: animationTime) {
                thumb.frame.origin.x = isOn ? frame.width - thumb.frame.width : 0
                thumb.backgroundColor = isOn ? thumbTintColor : .white
                backgroundColor = isOn ? onTintColor : .lightGray
            }
        }
    }

    public init() {
        super.init(
            frame: CGRect(origin: CGPoint(x: 0, y: 0), size: frameSize)
        )

        layer.cornerRadius = frame.height / 2
        
        thumb.frame.size = CGSize(width: thumbSize, height: thumbSize)
        thumb.frame.midY = frame.midY
        thumb.layer.cornerRadius = thumbSize / 2
        addSubview(thumb)

        tapGestureRecognizer.view = self
        tapGestureRecognizer.onPress = {
            self.isOn.toggle()
            self.onPress?(self.isOn)
        }
        addGestureRecognizer(tapGestureRecognizer)
    }
}
