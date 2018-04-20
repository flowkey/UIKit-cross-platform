open class UINavigationItem {
    open var title: String?
    open var rightBarButtonItem: UIBarButtonItemWithClosure?

    public init(title: String) {
        self.title = title
    }

    /// Note that `animated` is currently ignored
    open func setRightBarButton(_ item: UIBarButtonItemWithClosure?, animated: Bool) {
        rightBarButtonItem = item
    }
}


open class UIBarButtonItemWithClosure {
    open var action: (() -> Void)?
    open var title: String?

    public init() {}
    public convenience init(barButtonSystemItem systemItem: UIBarButtonSystemItem, action: (() -> Void)? = nil) {
        self.init()
        self.action = action

        if systemItem == .done {
            self.title = "Done"
        }
    }
}

public enum UIBarButtonSystemItem {
    case done
}
