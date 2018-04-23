open class UINavigationBarAndroid: UINavigationBar {
    override internal var barHeight: CGFloat { return 56 }

    override func setInitialAppearance() {
        super.setInitialAppearance()

        if let tintColor = tintColor {
            backgroundColor = tintColor

            // TODO: logic to determine how bright tintColor is
            // We should only do this if tintColor is dark enough!

            titleLabel.textColor = .white
            rightButton.tintColor = .white
        }

        leftButton.setImage(UIImage(path: "ic_arrow_back_black@2x.png"), for: .normal)
        rightButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.frame.origin.x = horizontalMargin
        if leftButton.isHidden == false {
            titleLabel.frame.origin.x += leftButton.frame.maxX
        }

        #if os(Android)
        // On Android we have a hardware back button
        if topItem?.rightBarButtonItem?.systemItem == .done {
            rightButton.isHidden = true
        }
        #endif
    }
}
