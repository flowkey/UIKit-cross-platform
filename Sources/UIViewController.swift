open class UIViewController: UIResponder {
    internal var _view: UIView?
    open var view: UIView! {
        get {
            loadViewIfNeeded()
            return _view
        }
        set(view) {
            _view = view
            view.next = self
            viewDidLoad()
        }
    }

    open var viewIsLoaded: Bool {
        return _view != nil
    }

    open var title: String? {
        didSet { navigationItem.title = title }
    }

    open internal(set) weak var navigationController: UINavigationController?
    open internal(set) weak var presentingViewController: UIViewController?

    // The `presentedViewController` is owned by its parent, but not the other way around:
    open internal(set) var presentedViewController: UIViewController?

    public init(nibName: String?, bundle: Bundle?) {
        super.init()
        if nibName != nil || bundle != nil {
            assertionFailure("We can't load nib files (yet?)!")
        }
    }

    public override convenience init () {
        self.init(nibName: nil, bundle: nil)
    }

    public func loadViewIfNeeded() {
        if !viewIsLoaded {
            loadView()
        }
    }

    open func loadView() {
        view = UIView()
    }

    // Most of these methods are designed to be overriden in `UIViewController` subclasses
    open func viewDidLoad() {}
    open func viewWillAppear(_ animated: Bool) {}
    open func viewDidAppear(_ animated: Bool) {}
    open func viewWillDisappear(_ animated: Bool) {}
    open func viewDidDisappear(_ animated: Bool) {}

    open func viewWillLayoutSubviews() {}
    open func viewDidLayoutSubviews() {}

    internal var animationTime: Double { return 0.4 }

    open func present(
        _ otherViewController: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        if presentedViewController != nil {
            print("Warning: attempted to present \(otherViewController), but \(self) is already presenting another view controller. Ignoring request.")
            return
        }

        if otherViewController.presentingViewController != nil {
            preconditionFailure("Tried to present \(otherViewController) but it is already being presented by \(otherViewController.presentingViewController!)")
        }

        presentedViewController = otherViewController
        otherViewController.presentingViewController = self

        otherViewController.view.frame = UIScreen.main.bounds
        otherViewController.viewWillAppear(animated)
        otherViewController.makeViewAppear(animated: animated, presentingViewController: self)
        otherViewController.viewDidAppear(animated)

        otherViewController.view.layoutSubviews()

        completion?()
    }

    open func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        // The `UINavigationController` dismisses the UIViewController at the top of its stack (potentially `self`) first.
        if let navigationController = navigationController {
            navigationController.dismiss(animated: animated, completion: completion)
            return
        }

        viewWillDisappear(animated)

        // This comes before completion because we may want to check if any presentedViewControllers are present before the animation is completed. In that case we're not really "presenting" anything anymore so we should return `nil`. This is particularly important for a `UIAlertController` that presents another UIViewController after dismissing itself.
        self.presentingViewController?.presentedViewController = nil

        makeViewDisappear(animated: animated, completion: { _ in
            self.view.removeFromSuperview()
            self.viewDidDisappear(animated)
            completion?()
            self.presentingViewController = nil
        })
    }

    open private(set) lazy var navigationItem: UINavigationItem = {
        let item = UINavigationItem(title: "") // there is no public initializer that takes no `title`
        item.title = self.title // possibly set `title` back to `nil` here
        return item
    }()


    open override func handleHardwareBackButtonPress() -> Bool {
        if view.superview is UIWindow {
            // Don't dismiss the last view controller, otherwise we'll be left with a blank screen:
            return super.handleHardwareBackButtonPress()
        }

        self.dismiss(animated: true)
        return true
    }

    /// This is just to provide compatibility with iOS for now, but we could feasibly
    /// use this property to e.g. put an Android device in "Immersive Mode" or similar.
    open var prefersHomeIndicatorAutoHidden: Bool {
        return false
    }

    /// Currently not implemented
    open func didReceiveMemoryWarning() {}


    // MARK: Mocking UIPresentationController with these two methods for now!

    internal func makeViewAppear(animated: Bool, presentingViewController: UIViewController) {
        presentingViewController.view.addSubview(view)

        let originalOriginY = view.frame.origin.y
        view.frame.origin.y = presentingViewController.view.bounds.maxY

        UIView.animate(withDuration: animated ? animationTime : 0.0, options: [.allowUserInteraction], animations: {
            self.view.frame.origin.y = originalOriginY
        }, completion: nil)
    }

    /// Note: you MUST call `completion` or you will end up in a broken state.
    internal func makeViewDisappear(animated: Bool, completion: @escaping (Bool) -> Void) {
        UIView.animate(
            withDuration: animated ? animationTime : 0.0,
            options: [.allowUserInteraction],
            animations: {
                view.frame.origin.y = view.superview?.bounds.height ?? view.frame.height
        }, completion: completion)
    }
}
