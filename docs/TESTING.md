# Testing Guidelines

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