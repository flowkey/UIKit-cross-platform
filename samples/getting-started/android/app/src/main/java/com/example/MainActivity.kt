package com.example

import android.os.Bundle
import com.flowkey.uikit.UIKitActivity

class MainActivity: UIKitActivity() {
    companion object {
        init {
            System.loadLibrary("DemoApp")
        }
    }
}
