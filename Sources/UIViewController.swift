
public class UIPresentationController {

}

public class UIPopoverPresentationController: UIPresentationController {
    open var sourceView: UIView?
    open var sourceRect: CGRect = .zero

    public override init() {
        super.init()
    }
}


open class UIViewController: UIResponder {
    public var title: String?
    private var _view: UIView?

    open var view: UIView! {
        get {
            loadViewIfNeeded()
            return _view
        }
        set { _view = newValue }
    }

    open internal(set) lazy var navigationItem = UINavigationItem()

    open var viewIsLoaded: Bool {
        return _view != nil
    }

    open internal(set) var presentingViewController: UIViewController?
    open internal(set) var presentedViewController: UIViewController?

    open var modalPresentationStyle: UIModalPresentationStyle = .popover

    public var popoverPresentationController: UIPopoverPresentationController?

    public init(nibName: String?, bundle: Bundle?) {
        super.init()
        if nibName != nil || bundle != nil {
            assertionFailure("We can't load nib files (yet?)!")
        }
    }

    public func loadViewIfNeeded() {
        if !viewIsLoaded {
            loadView()
            viewDidLoad()
        }
    }

    open func loadView() {
        view = UIView()
    }

    // Most of these methods are designed to be overriden in `UIViewController` subclasses
    open func viewDidLoad() {}

    open func viewWillAppear(_ animated: Bool) {}
    open func viewDidAppear() {}
    open func viewWillDisappear() {}
    open func viewDidDisappear() {}

    open func viewWillLayoutSubviews() {}
    open func viewDidLayoutSubviews() {}

    open func present(_ otherViewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        otherViewController.viewWillAppear(animated)

        // TODO: Add a background modal overlay here first. Also, actually animate the transition in.
        self.view.addSubview(otherViewController.view)

        // XXX: Not sure if `viewDidAppear` should occur before or after layouting subviews
        otherViewController.viewWillLayoutSubviews()
        otherViewController.view.layoutSubviews()
        otherViewController.viewDidLayoutSubviews()

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

public enum UIModalPresentationStyle {
    case popover
    case formSheet
    // TODO: add others
}
