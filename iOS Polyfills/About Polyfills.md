## What is this folder? 

iOS Polyfills are patch files that are necessary for many UIKit-crossplatform projects to work correctly with iOS. You will need them if you use `UIButton` or `UIGestureRecognizer`. 

## How to use these files?

Drag-and-drop them into your project and _make sure `Copy items if needed` is *unchecked*_ on the Xcode dialog. Once they are added to your project, please use UIKit-crossplatform API for the classes in question (rather than the native iOS API).

For example, after adding `Button+iOS.swift`, you will need to change all your `UIButtons` to `Buttons` and use the appropriate API. The API is very similar, the most significant difference being how methods are added to Buttons. UIKit-crossplatform will require you to use `myButton.onPress = { /*a closure with some code*/}`, rather than `addTarget:`. Very often this will be the only necessary change, apart from Find-and-replace to use the `Button` keyword everywhere that you previously had `UIButtons`.

## Why is this necessary?

UIKit-crossplatform is written in Swift, while some parts of the API that UIKit uses are Objective-C. Things like the aforementioned `addTarget:` are not easily reproducible in Swift. We use these polyfill patch files as a solution (that hopefully we can still improve upon).
