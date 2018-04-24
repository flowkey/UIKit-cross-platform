open class UINavigationBarAndroid: UINavigationBar {
    override internal var barHeight: CGFloat { return 56 }

    override func platformSpecificSetup() {
        backButton = UINavigationButtonAndroid()

        super.platformSpecificSetup()

        if let tintColor = tintColor {
            backgroundColor = tintColor
        }

        let backButtonImage: UIImage?
        if backgroundColor?.isDarkEnoughToWarrantWhiteText() == true {
            titleLabel.textColor = .white
            rightButton.tintColor = .white
            backButtonImage = UIImage(path: "ic_arrow_back_white@2x.png")
        } else {
            backButtonImage = UIImage(path: "ic_arrow_back_black@2x.png")
        }

        backButton.setImage(backButtonImage, for: .normal)

        let originalLeftButtonOnPress = backButton.onPress
        backButton.onPress = { [weak self] in
            if self?.items?.count != 1 {
                originalLeftButtonOnPress?()
            } else {
                // We are the last item, or there are no items. Dismiss!
                (self?.next as? UINavigationController)?.dismiss(animated: true)
            }
        }

        rightButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
    }

    override func updateUI() {
        // Don't call super here because the UX/UI is different compared to iOS.

        backButton.isHidden = false // always show button
        backButton.setTitle(nil, for: .normal)

        setTitleLabelText()
        setRightButtonTitle()

        // On Android we have both a hardware back button and a software back button (on the left of the toolbar) that performs "done" as well when the stack is empty.
        if topItem?.rightBarButtonItem?.systemItem == .done {
            rightButton.isHidden = true
        } else {
            rightButton.isHidden = false
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let buttonSize = CGSize(width: barHeight / 2, height: barHeight / 2)
        backButton.imageView?.bounds.size = buttonSize // change bounds.size to keep centred
        backButton.frame.size = CGSize(width: buttonSize.width * 1.25, height: buttonSize.height * 1.25)
        backButton.center.y = bounds.midY
        backButton.layer.cornerRadius = (backButton.frame.width / 2)

        titleLabel.frame.origin.x = horizontalMargin
        if backButton.isHidden == false {
            titleLabel.frame.origin.x += backButton.frame.maxX
        }
    }
}

private class UINavigationButtonAndroid: Button {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = (isHighlighted ? UIColor.black.withAlphaComponent(0.1) : .clear)
        }
    }
}

extension UIColor {
    func isDarkEnoughToWarrantWhiteText() -> Bool {
        let thresholdLevel = Int(UInt8.max) / 2
        let totalColourIntensity = Int(red) + Int(green) + Int(blue)
        return (totalColourIntensity / 3) < thresholdLevel
    }
}
