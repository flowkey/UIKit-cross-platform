package com.flowkey.uikit

import android.app.Activity
import android.content.pm.ActivityInfo
import android.os.Bundle

open class UIKitActivity : Activity() {
    var view: UIKitView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        setTheme(android.R.style.Theme_Black_NoTitleBar_Fullscreen)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE

        super.onCreate(savedInstanceState)
        val view = UIKitView(this)
        setContentView(view)
        this.view = view
    }

    override fun onDestroy() {
        view?.removeFrameCallbackAndQuit()
        super.onDestroy()
    }
}
