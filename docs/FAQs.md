# FAQs / Troubleshooting

## Compile Errors


```
externalNativeBuildDebug FAILED
ninja error due to missing swift file
```

Example Error Message:
```bash
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:externalNativeBuildDebug'.
> Build command failed.
  Error while executing process cmake with arguments {...}
  ninja: error: {...} '{SomeSwiftFile}.swift', needed by '../swiftpm/debug/lib{yourProduct}.so', missing and no known rule to make it
```

How to resolve it:

- open Android Studio
- Build -> Refresh Linked C++ Projects
- Rebuild your Project


------
... more TBD soon