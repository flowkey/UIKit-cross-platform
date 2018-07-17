package com.example

import android.os.Bundle
import com.flowkey.uikit.UIKitActivity

class MainActivity: UIKitActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        callSwiftFromKotlin("hey swift")
    }

    companion object {
        init {
            System.loadLibrary("DemoApp")
        }
    }

    external fun callSwiftFromKotlin(message: String)
}
