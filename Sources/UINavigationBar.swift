open class UINavigationBar: UIView {
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
        titleLabel.text = topItem?.title
        rightButton.setTitle(topItem?.rightBarButtonItem?.title, for: .normal)
        rightButton.onPress = { [weak self] in
            self?.topItem?.rightBarButtonItem?.action?()
            print("Pressed")
        }
    }

    open override func didMoveToSuperview() {
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        rightButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        addSubview(titleLabel)
        addSubview(leftButton)
        addSubview(rightButton)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: bounds.midX, y: bounds.midY)

        rightButton.sizeToFit()
        rightButton.frame.maxX = bounds.maxX - 20
        rightButton.center.y = bounds.midY

        // XXX: layout left button
    }

    let titleLabel = UILabel()
    let leftButton = Button()
    let rightButton = Button()

    open func pushItem(_ item: UINavigationItem, animated: Bool) {
        items = items ?? []
        items?.append(item)
    }
}
