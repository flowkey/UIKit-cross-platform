cmake_minimum_required(VERSION 3.15.0)

project(UIKit LANGUAGES C Swift)

set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

add_library(UIKit SHARED
    Sources/$<$<PLATFORM_ID:Android>:androidNativeInit.swift>
    Sources/$<$<PLATFORM_ID:Android>:AVPlayer+Android.swift>
    Sources/$<$<PLATFORM_ID:Android>:AVPlayerLayer+Android.swift>
    Sources/$<$<PLATFORM_ID:Android>:AVURLAsset+Android.swift>

    Sources/$<$<PLATFORM_ID:Darwin>:AVPlayerItem+Mac.swift>
    Sources/$<$<PLATFORM_ID:Darwin>:AVPlayerLayer+Mac.swift>
    Sources/$<$<PLATFORM_ID:Darwin>:UIApplicationMain+Mac.swift>
    Sources/$<$<PLATFORM_ID:Darwin>:VideoTexture+Mac.swift>

    Sources/AnimatableProperty.swift
    Sources/AnimationKeyPath.swift
    Sources/Bundle.swift
    Sources/Button.swift
    Sources/CAAction.swift
    Sources/CABasicAnimation+updateProgress.swift
    Sources/CABasicAnimation.swift
    Sources/CABasicAnimationPrototype.swift
    Sources/CALayer+ContentsGravity.swift
    Sources/CALayer+SDL.swift
    Sources/CALayer+animations.swift
    Sources/CALayer.swift
    Sources/CAMediaTimingFunction.swift
    Sources/CASpringAnimation.swift
    Sources/CASpringAnimationPrototype.swift
    Sources/CATransaction.swift
    Sources/CATransform3D+SDL_gpu.swift
    Sources/CATransform3D+animations.swift
    Sources/CATransform3D.swift
    Sources/CGAffineTransform.swift
    Sources/CGDataProvider.swift
    Sources/CGFloat.swift
    Sources/CGImage.swift
    Sources/CGPath.swift
    Sources/CGPoint+animations.swift
    Sources/CGPoint.swift
    Sources/CGRect+animations.swift
    Sources/CGRect.swift
    Sources/CGSize.swift
    Sources/Data+fromRelativePathCrossPlatform.swift
    Sources/DisplayLink.swift
    Sources/FontRenderer+renderAttributedString.swift
    Sources/FontRenderer+singleLineSize.swift
    Sources/FontRenderer.swift
    Sources/Logging.swift
    Sources/MaskingShaders.swift
    Sources/MeteringView.swift
    Sources/NSAttributedString.swift
    Sources/NSAttributedStringKey.swift
    Sources/NSMutableAttributedString.swift
    Sources/NSNotification.swift
    Sources/NSRange.swift
    Sources/Notification.swift
    Sources/NotificationCenter.swift
    Sources/SDL+JNIExtensions.swift
    Sources/SDL2-Shims.swift
    Sources/Shader.swift
    Sources/ShaderProgram+mask.swift
    Sources/ShaderProgram.swift
    Sources/Timer.swift
    Sources/UIAccessibilityIdentification.swift
    Sources/UIActivityIndicatorView.swift
    Sources/UIAlertAction.swift
    Sources/UIAlertController.swift
    Sources/UIAlertControllerBackdrop.swift
    Sources/UIAlertControllerView.swift
    Sources/UIApplication+Notifications.swift
    Sources/UIApplication+handleSDLEvents.swift
    Sources/UIApplication.swift
    Sources/UIApplicationDelegate.swift
    Sources/UIApplicationMain.swift
    Sources/UIColor.swift
    Sources/UIControl.swift
    Sources/UIEdgeInsets.swift
    Sources/UIEvent.swift
    Sources/UIFont.swift
    Sources/UIGestureRecognizer.swift
    Sources/UIGestureRecognizerDelegate.swift
    Sources/UIImage.swift
    Sources/UIImageView.swift
    Sources/UILabel.swift
    Sources/UIModalPresentationStyle.swift
    Sources/UINavigationBar.swift
    Sources/UINavigationBarAndroid.swift
    Sources/UINavigationController.swift
    Sources/UINavigationControllerContainerView.swift
    Sources/UINavigationItem.swift
    Sources/UIPanGestureRecognizer.swift
    Sources/UIPinchGestureRecognizer.swift
    Sources/UIProgressView.swift
    Sources/UIResponder.swift
    Sources/UIScreen+Errors.swift
    Sources/UIScreen+render.swift
    Sources/UIScreen.swift
    Sources/UIScrollView+indicatorsInternal.swift
    Sources/UIScrollView+velocity.swift
    Sources/UIScrollView.swift
    Sources/UITapGestureRecognizer.swift
    Sources/UITextView.swift
    Sources/UITouch.swift
    Sources/UIView+SDL.swift
    Sources/UIView+animate.swift
    Sources/UIView+printViewHierarchy.swift
    Sources/UIView.swift
    Sources/UIViewAnimationGroup.swift
    Sources/UIViewController.swift
    Sources/UIVisualEffect.swift
    Sources/UIVisualEffectView.swift
    Sources/UIWindow+TouchHandling.swift
    Sources/UIWindow+hardwareBackButton.swift
    Sources/UIWindow.swift
    )

set_target_properties(UIKit PROPERTIES
  INTERFACE_LINK_DIRECTORIES $<TARGET_LINKER_FILE_DIR:UIKit>
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

add_subdirectory(swift-jni)
target_link_libraries(UIKit PRIVATE JNI)

add_subdirectory(SDL)
target_link_libraries(UIKit PRIVATE SDL)

# target_compile_options(UIKit PRIVATE
#        $<$<BOOL:ENABLE_TESTING>:-enable-testing>)

# install(TARGETS UIKit LIBRARY DESTINATION lib)
