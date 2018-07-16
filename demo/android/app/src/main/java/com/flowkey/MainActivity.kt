package com.flowkey.DemoApp

import com.flowkey.uikit.UIKitActivity

class MainActivity: UIKitActivity() {
    companion object {
        init {
            System.loadLibrary("DemoApp")
        }
    }
}
