open class UINavigationBar: UIView {
    internal var barHeight: CGFloat { return 40 }
    internal var horizontalMargin: CGFloat { return 20 }

    open var items: [UINavigationItem]? = nil {
        didSet { updateUI() }
    }

    open var topItem: UINavigationItem? {
        return items?.last
    }

    open var backItem: UINavigationItem? {
        guard let items = items, items.count >= 2 else { return nil }

        let secondLastItemIndex = items.indices.last! - 1
        return items[secondLastItemIndex]
    }

    internal func updateUI() {
        if let backItem = backItem {
            backButton.isHidden = false
            backButton.setTitle(backItem.title ?? "Back", for: .normal)
        } else {
            backButton.isHidden = true
        }

        setTitleLabelText()
        setRightButtonTitle()
    }

    internal func setTitleLabelText() {
        titleLabel.text = topItem?.title
    }

    internal func setRightButtonTitle() {
        rightButton.setTitle(topItem?.rightBarButtonItem?.title, for: .normal)
    }

    internal func platformSpecificSetup() {
        frame.size.height = self.barHeight // varies per platform
        backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1)

        backButton.onPress = { [weak self] in
            self?.popItem(animated: true)
        }

        rightButton.onPress = { [weak self] in
            self?.topItem?.rightBarButtonItem?.action?()
        }

        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        rightButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        rightButton.tintColor = tintColor

        addSubview(titleLabel)
        addSubview(backButton)
        addSubview(rightButton)
    }

    open override func layoutSubviews() {
        backButton.sizeToFit()
        backButton.frame.origin.x = horizontalMargin
        backButton.center.y = bounds.midY

        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: bounds.midX, y: bounds.midY)

        rightButton.sizeToFit()
        rightButton.frame.maxX = bounds.maxX - horizontalMargin
        rightButton.center.y = bounds.midY
    }

    internal var titleLabel = UILabel()
    internal var backButton = Button()
    internal var rightButton = Button()

    open func pushItem(_ item: UINavigationItem, animated: Bool) {
        items = items ?? []
        items?.append(item)
    }

    @discardableResult
    open func popItem(animated: Bool) -> UINavigationItem? {
        return items?.popLast()
    }
}
