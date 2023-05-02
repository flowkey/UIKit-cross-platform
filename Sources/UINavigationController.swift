open class UINavigationController: UIViewController {
    /// Note: not currently implemented!
    open var modalPresentationStyle: UIModalPresentationStyle = .formSheet

    public init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        pushViewController(rootViewController, animated: false)
        updateNavigationBarItems()
    }

    open override func loadView() {
        view = UINavigationControllerContainerView()
        view.addSubview(transitionView)
        view.addSubview(navigationBar)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.next = self
        transitionView.next = self
    }

    open internal(set) var navigationBar = UINavigationBarAndroid()
    internal var transitionView = UIView() // animates the other views on push/pop

    open internal(set) var viewControllers: [UIViewController] = [] {
        didSet { updateNavigationBarItems() }
    }

    private func updateNavigationBarItems() {
        navigationBar.items = viewControllers.map { $0.navigationItem }
    }

    private func updateUIFromViewControllerStack(animated: Bool) {
        guard _view != nil else { return }
        if presentedViewController === viewControllers.last { return }

        transitionView.subviews.forEach { $0.removeFromSuperview() }
        presentedViewController = viewControllers.last

        if let viewOnTopOfStack = viewControllers.last?.view {
            // TODO: Animate here
            viewOnTopOfStack.frame = transitionView.bounds
            presentedViewController?.viewWillAppear(animated)
            transitionView.addSubview(viewOnTopOfStack)
            presentedViewController?.viewDidAppear(animated)
        }
    }

    open func pushViewController(_ otherViewController: UIViewController, animated: Bool) {
        otherViewController.navigationController = self
        otherViewController.presentingViewController = self
        viewControllers.append(otherViewController)
        updateUIFromViewControllerStack(animated: animated)
    }

    open func popViewController(animated: Bool) -> UIViewController? {
        // You can't pop the rootViewController (per iOS docs)
        if viewControllers.count <= 1 { return nil }

        let topOfStack = viewControllers.popLast()!
        topOfStack.dismiss(animated: false) // XXX: not sure if this is correct.
        updateUIFromViewControllerStack(animated: animated)
        return topOfStack
    }

    open override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        guard self !== UIApplication.shared?.keyWindow?.rootViewController else {
            completion?()
            return
        }

        let topOfStack = viewControllers.last
        topOfStack?.viewWillDisappear(animated)

        super.dismiss(animated: animated, completion: {
            // XXX: without the following line it's impossible to present the
            // `topOfStack` viewController again - you just get a blank screen.
            // Although it's correct to have this line here, it's creepy that it breaks
            // without it. We should investigate a possible memory leak or logic error.
            topOfStack?.view?.removeFromSuperview()
            topOfStack?.viewDidDisappear(animated)

            completion?()
        })
    }

    open override func viewWillAppear(_ animated: Bool) {
        if viewControllers.isEmpty {
            preconditionFailure(
                "A UINavigationController must contain at least one other view controller when it is presented")
        }

        super.viewWillAppear(animated)
        navigationBar.platformSpecificSetup()
        navigationBar.frame.size.width = view.bounds.width
        transitionView.frame = view.bounds

        // This `animated` bool is unrelated to the one passed into viewWillAppear:
        updateUIFromViewControllerStack(animated: false)
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        navigationBar.frame.size.width = view.bounds.width
        transitionView.frame = view.bounds
    }

    open override func handleHardwareBackButtonPress() -> Bool {
        if let onPress = navigationBar.backButton.onPress {
            onPress()
            return true
        } else {
            return super.handleHardwareBackButtonPress()
        }
    }
}
