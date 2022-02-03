// Note: we deliberately don't wrap UISwitch.
// This allows us to have a somewhat custom API free of objc selectors etc.

open class Switch: UIControl {
    private let tapGestureRecognizer = UITapGestureRecognizer()
    
    private var thumb = SwitchThumb()

    public var onTintColor: UIColor? = defaultOnTintColor
    public var thumbTintColor: UIColor? = defaultThumbColor

    public var onPress: ((Bool) -> Void)?

    public var isOn = false {
        didSet {
            thumb.frame.origin.x = isOn ? frame.width - thumb.frame.width : 0
            thumb.backgroundColor = isOn ? thumbTintColor : offThumbColor
            backgroundColor = isOn ? onTintColor : offTrackColor
        }
    }

    public init() {
        super.init(
            frame: CGRect(origin: CGPoint(x: 0, y: 0), size: frameSize)
        )

        layer.cornerRadius = frame.height / 2
                
        backgroundColor = isOn ? onTintColor : .lightGray
    
        thumb.frame.midY = frame.midY
        thumb.backgroundColor = isOn ? thumbTintColor : .white
        addSubview(thumb)

        tapGestureRecognizer.view = self
        tapGestureRecognizer.onPress = {
            self.setOn(!self.isOn, animated: true)
            self.onPress?(self.isOn)
        }
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    public func setOn(_ isOn: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: animationTime) {
                self.isOn = isOn
            }
        } else {
            self.isOn = isOn
        }
    }

}


private final class SwitchThumb: UIView {
    let thumb = UIView(frame: .zero)
    let shadow = UIView(frame: .zero)
    
    override var backgroundColor: UIColor? {
        get { thumb.backgroundColor }
        set { thumb.backgroundColor = newValue }
    }

    init() {
        thumb.frame.size = CGSize(width: thumbSize, height: thumbSize)
        thumb.layer.cornerRadius = thumbSize / 2
        
        let shadowSize = thumbSize + 2
        shadow.frame.size = CGSize(width: shadowSize, height: shadowSize)
        shadow.frame.midX = thumb.frame.midX
        shadow.frame.midY = thumb.frame.midY + 2
        shadow.layer.cornerRadius = shadowSize / 2
        shadow.backgroundColor = .lightGray.withAlphaComponent(0.4)
        
        super.init(frame: .zero)
        
        frame.size = CGSize(width: thumbSize, height: thumbSize)
        layer.cornerRadius = thumbSize / 2
        
        self.addSubview(shadow)
        self.addSubview(thumb)
    }
    
}

private let frameSize = CGSize(width: 51, height: 21)
private let thumbSize = CGFloat(31.0)
private let animationTime = 0.25

private let defaultOnTintColor = CGColor(red: 169 / 255, green: 218 / 255 , blue: 214 / 255, alpha: 1)
private let defaultThumbColor = CGColor(red: 14 / 255, green: 136 / 255 , blue: 122 / 255, alpha: 1)

private let offThumbColor = CGColor(red: 176 / 255, green: 176 / 255 , blue: 176 / 255, alpha: 1)
private let offTrackColor = CGColor(red: 225 / 255, green: 225 / 255 , blue: 225 / 255, alpha: 1)

