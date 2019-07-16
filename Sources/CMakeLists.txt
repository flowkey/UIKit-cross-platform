add_library(UIKit SHARED
    $<$<PLATFORM_ID:Android>:androidNativeInit.swift>
    $<$<PLATFORM_ID:Android>:AVPlayer+Android.swift>
    $<$<PLATFORM_ID:Android>:AVPlayerLayer+Android.swift>
    $<$<PLATFORM_ID:Android>:AVURLAsset+Android.swift>

    $<$<PLATFORM_ID:Darwin>:AVPlayerItem+Mac.swift>
    $<$<PLATFORM_ID:Darwin>:AVPlayerLayer+Mac.swift>
    $<$<PLATFORM_ID:Darwin>:UIApplicationMain+Mac.swift>
    $<$<PLATFORM_ID:Darwin>:VideoTexture+Mac.swift>

    AnimatableProperty.swift
    AnimationKeyPath.swift
    Bundle.swift
    Button.swift
    CAAction.swift
    CABasicAnimation+updateProgress.swift
    CABasicAnimation.swift
    CABasicAnimationPrototype.swift
    CALayer+ContentsGravity.swift
    "CALayer+SDL.swift"
    CALayer+animations.swift
    CALayer.swift
    CAMediaTimingFunction.swift
    CASpringAnimation.swift
    CASpringAnimationPrototype.swift
    CATransaction.swift
    "CATransform3D+SDL_gpu.swift"
    CATransform3D+animations.swift
    CATransform3D.swift
    CGAffineTransform.swift
    CGDataProvider.swift
    CGFloat.swift
    CGImage.swift
    CGPath.swift
    CGPoint+animations.swift
    CGPoint.swift
    CGRect+animations.swift
    CGRect.swift
    CGSize.swift
    Data+fromRelativePathCrossPlatform.swift
    DisplayLink.swift
    FontRenderer+renderAttributedString.swift
    FontRenderer+singleLineSize.swift
    FontRenderer.swift
    Logging.swift
    MaskingShaders.swift
    MeteringView.swift
    NSAttributedString.swift
    NSAttributedStringKey.swift
    NSMutableAttributedString.swift
    NSNotification.swift
    NSRange.swift
    Notification.swift
    NotificationCenter.swift
    SDL+JNIExtensions.swift
    "SDL2 Shims.swift"
    Shader.swift
    ShaderProgram+mask.swift
    ShaderProgram.swift
    Timer.swift
    UIAccessibilityIdentification.swift
    UIActivityIndicatorView.swift
    UIAlertAction.swift
    UIAlertController.swift
    UIAlertControllerBackdrop.swift
    UIAlertControllerView.swift
    UIApplication+Notifications.swift
    UIApplication+handleSDLEvents.swift
    UIApplication.swift
    UIApplicationDelegate.swift
    UIApplicationMain.swift
    UIColor.swift
    UIControl.swift
    UIEdgeInsets.swift
    UIEvent.swift
    UIFont.swift
    UIGestureRecognizer.swift
    UIGestureRecognizerDelegate.swift
    UIImage.swift
    UIImageView.swift
    UILabel.swift
    UIModalPresentationStyle.swift
    UINavigationBar.swift
    UINavigationBarAndroid.swift
    UINavigationController.swift
    UINavigationControllerContainerView.swift
    UINavigationItem.swift
    UIPanGestureRecognizer.swift
    UIPinchGestureRecognizer.swift
    UIProgressView.swift
    UIResponder.swift
    UIScreen+Errors.swift
    UIScreen+render.swift
    UIScreen.swift
    UIScrollView+indicatorsInternal.swift
    UIScrollView+velocity.swift
    UIScrollView.swift
    UITapGestureRecognizer.swift
    UITextView.swift
    UITouch.swift
    "UIView+SDL.swift"
    UIView+animate.swift
    UIView+printViewHierarchy.swift
    UIView.swift
    UIViewAnimationGroup.swift
    UIViewController.swift
    UIVisualEffect.swift
    UIVisualEffectView.swift
    UIWindow+TouchHandling.swift
    UIWindow+hardwareBackButton.swift
    UIWindow.swift
    )

target_compile_options(UIKit PRIVATE
       $<$<BOOL:ENABLE_TESTING>:-enable-testing>)

# set_target_properties(UIKit PROPERTIES
#        INTERFACE_LINK_DIRECTORIES ${CMAKE_BINARY_DIR}
#        INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

target_link_options(UIKit PRIVATE
       -Xlinker -soname=libUIKit.so)

install(TARGETS UIKit LIBRARY DESTINATION lib)
