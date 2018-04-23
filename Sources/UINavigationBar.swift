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

        let lastItemIndex = items.endIndex - 1 // == items.indexOf(items.last)
        let secondLastItemIndex = lastItemIndex - 1

        return items[secondLastItemIndex]
    }

    private func updateUI() {
        if let backItem = backItem {
            leftButton.isHidden = false
            leftButton.setTitle(backItem.title ?? "Back", for: .normal)
            leftButton.onPress = { [weak self] in
                self?.popItem(animated: true)
            }
        } else {
            leftButton.isHidden = true
        }

        titleLabel.text = topItem?.title

        rightButton.setTitle(topItem?.rightBarButtonItem?.title, for: .normal)
        rightButton.onPress = { [weak self] in
            self?.topItem?.rightBarButtonItem?.action?()
        }
    }

    internal func setInitialAppearance() {
        frame.size.height = self.barHeight // varies per platform
        backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.91)

        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        rightButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        rightButton.tintColor = tintColor

        addSubview(titleLabel)
        addSubview(leftButton)
        addSubview(rightButton)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        leftButton.sizeToFit()
        leftButton.frame.origin.x = horizontalMargin
        leftButton.center.y = bounds.midY

        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: bounds.midX, y: bounds.midY)

        rightButton.sizeToFit()
        rightButton.frame.maxX = bounds.maxX - horizontalMargin
        rightButton.center.y = bounds.midY
    }

    let titleLabel = UILabel()
    let leftButton = Button()
    let rightButton = Button()

    open func pushItem(_ item: UINavigationItem, animated: Bool) {
        items = items ?? []
        items?.append(item)
    }

    @discardableResult
    open func popItem(animated: Bool) -> UINavigationItem? {
        return items?.popLast()
    }
}
