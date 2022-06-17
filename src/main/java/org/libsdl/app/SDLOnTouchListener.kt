package main.java.org.libsdl.app

import android.text.method.Touch
import android.view.InputDevice
import android.view.MotionEvent
import android.view.View
import org.libsdl.app.SDLActivity
import kotlin.math.min


interface SDLOnTouchListener: View.OnTouchListener {

    var mWidth: Float
    var mHeight: Float
    var mHasFocus: Boolean

    fun onNativeMouse(button: Int, action: Int, x: Float, y: Float)
    fun onNativeTouchUIKit(touchParameters: TouchParameters)

    // Touch events
    override fun onTouch(v: View, event: MotionEvent): Boolean {
        /* Ref: http://developer.android.com/training/gestures/multi.html */
        val touchDevId = event.deviceId
        val action = event.actionMasked
        val timestamp = event.eventTime

        if (event.source == InputDevice.SOURCE_MOUSE && SDLActivity.mSeparateMouseAndTouch) {
            val mouseButton = try { event.buttonState } catch (e: Exception) { 1 } // 1 is left button
            this.onNativeMouse(mouseButton, action, event.getX(0), event.getY(0))
            return true
        }

        when (action) {
            MotionEvent.ACTION_MOVE -> {
                for (i in 0 until event.pointerCount) {
                    val (fingerId, x, y, pressure) = event.touchValues(i)
                    this.callOnNativeTouchIfHasFocus(touchDevId, fingerId, action, x, y, pressure, timestamp)
                }
            }

            MotionEvent.ACTION_UP,
            MotionEvent.ACTION_DOWN,
            MotionEvent.ACTION_POINTER_UP,
            MotionEvent.ACTION_POINTER_DOWN -> {
                val (fingerId, x, y, pressure) = event.touchValues(event.actionIndex)
                this.callOnNativeTouchIfHasFocus(touchDevId, fingerId, action, x, y, pressure, timestamp)
            }

            MotionEvent.ACTION_CANCEL -> {
                for (i in 0 until event.pointerCount) {
                    val (fingerId, x, y, pressure) = event.touchValues(i)
                    this.callOnNativeTouchIfHasFocus(touchDevId, fingerId, MotionEvent.ACTION_UP, x, y, pressure, timestamp)
                }
            }
        }

        return true
    }

    fun callOnNativeTouchIfHasFocus(
            touchDevId: Int,
            pointerFingerId: Int,
            action: Int,
            x: Float,
            y: Float,
            p: Float,
            t: Long
    ) {
        // check if we have focus because of a crash when re-entering the player 
        // from a background state while touching (JNIEnv dead)
        if (this.mHasFocus) {
            this.onNativeTouchUIKit(TouchParameters(touchDevId, pointerFingerId, action, x, y, p, t))
        }
    }
}


private data class TouchValues(val fingerId: Int, val x: Float, val y: Float, val pressure: Float)

private fun MotionEvent.touchValues(i: Int): TouchValues {
    return TouchValues(
            getPointerId(i),
            getX(i),
            getY(i),
            // Pressure can be > 1.0 on some devices. See getPressure(i) docs.
            min(this.getPressure(i), 1.0f)
    )
}

class TouchParameters(
    val touchDeviceId: Int,
    val pointerFingerId: Int,
    val action: Int,
    val x: Float,
    val y: Float,
    val pressure: Float,
    val timestamp: Long
)

class EdgeInsets(
        val top: Int,
        val left: Int,
        val bottom: Int,
        val right: Int
)