package main.java.org.libsdl.app

import android.view.InputDevice
import android.view.KeyEvent
import android.view.View


interface SDLOnKeyListener: View.OnKeyListener {

    fun onNativeKeyDown(keycode: Int)
    fun onNativeKeyUp(keycode: Int)

    // Key events
    override fun onKey(v: View, keyCode: Int, event: KeyEvent): Boolean {
        if (event.source and InputDevice.SOURCE_KEYBOARD != 0) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                //Log.v(TAG, "key down: " + keyCode);
                this.onNativeKeyDown(keyCode)
                return true
            } else if (event.action == KeyEvent.ACTION_UP) {
                //Log.v(TAG, "key up: " + keyCode);
                this.onNativeKeyUp(keyCode)
                return true
            }
        }

        if (event.source and InputDevice.SOURCE_MOUSE != 0) {
            // on some devices key events are sent for mouse BUTTON_BACK/FORWARD presses
            // they are ignored here because sending them as mouse input to SDL is messy
            if (keyCode == KeyEvent.KEYCODE_BACK || keyCode == KeyEvent.KEYCODE_FORWARD) {
                when (event.action) {
                    KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP ->
                        // mark the event as handled or it will be handled by system
                        // handling KEYCODE_BACK by system will call onBackPressed()
                        return true
                }
            }
        }

        return false
    }
}