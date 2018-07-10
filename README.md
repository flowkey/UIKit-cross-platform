[![CircleCI](https://circleci.com/gh/flowkey/UIKit-SDL.svg?style=shield&circle-token=2bc60653f4bb369754b04d97d324d9ba2bee6c6b)](https://circleci.com/gh/flowkey/UIKit-SDL)
[![Swift4.1](https://img.shields.io/badge/swift-4.1-green.svg?style=flat)](https://swift.org/)


# UIKit-SDL
API-match UIView-based hierarchies built in UIKit on Mac/Linux/Android using SDL2

![uikit-sdl](https://user-images.githubusercontent.com/10008938/27796338-f6831442-6009-11e7-8ec8-fa5e092136fe.png)


## Some Notes on Testing
- try to split up tests, even if that means more boilerplate for preconditions
- avoid vague test names, instead try to describe what exactly the test aimes for - even if the name gets a little longer
- if possible, try to stick to following code format in order to reduce cognitive load when reading:
```
func testSomethingSpecific() {
    (no empty line)
    Precondition(s)
    (empty line)
    Action(s)
    (empty line)
    Expectations/Assertions
    (no empty line)
}
```
