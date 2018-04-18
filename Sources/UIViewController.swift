open class UIViewController: UIResponder {
    public init(nibName: String?, bundle: Bundle?) {
        super.init()
        if nibName != nil || bundle != nil {
            assertionFailure("We can't load nib files (yet?)!")
        }
    }

    open private(set) var view: UIView!
    open private(set) var viewIsLoaded = false

    open func loadView() {
        view = UIView()
        viewIsLoaded = true
        viewDidLoad()
    }

    public func loadViewIfNeeded() {
        if !viewIsLoaded {
            loadView()
        }
    }

    // Most of these methods are designed to be overriden in `UIViewController` subclasses
    open func viewDidLoad() {}

    open func viewWillAppear(_ animated: Bool) {}
    open func viewDidAppear() {}
    open func viewWillDisappear() {}
    open func viewDidDisappear() {}

    open func viewWillLayoutSubviews() {}

    open func present(_ otherViewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        otherViewController.viewWillAppear(animated)

        // TODO: Add a background modal overlay here first. Also, actually animate the transition in.
        self.view.addSubview(otherViewController.view)

        // XXX: Not sure if this order is correct
        otherViewController.viewWillLayoutSubviews()
        otherViewController.view.layoutSubviews()

        otherViewController.viewDidAppear()
        completion?()
    }

    open func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        // TODO: Actually animate.
        self.viewWillDisappear()
        self.view.removeFromSuperview()
        self.viewDidDisappear()
        completion?()
    }
}
