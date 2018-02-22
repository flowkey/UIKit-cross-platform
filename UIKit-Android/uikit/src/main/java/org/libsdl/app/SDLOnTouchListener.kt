package main.java.org.libsdl.app

import android.view.InputDevice
import android.view.MotionEvent
import android.view.View
import kotlin.math.min


interface SDLOnTouchListener: View.OnTouchListener {

    companion object {
        // If we want to separate mouse and touch events.
        // This is only toggled in native code when a hint is set!
        // This is the only property that remains static - we probably won't use it at all long-term
        // and it is a major overhaul to change the native C code (there are a lot of dependencies)
        var mSeparateMouseAndTouch: Boolean = false
    }

    var mWidth: Float
    var mHeight: Float

    fun onNativeMouse(button: Int, action: Int, x: Float, y: Float)
    fun onNativeTouch(touchDevId: Int, pointerFingerId: Int, action: Int, x: Float, y: Float, p: Float)

    // Touch events
    override fun onTouch(v: View, event: MotionEvent): Boolean {
        /* Ref: http://developer.android.com/training/gestures/multi.html */
        val touchDevId = event.deviceId
        val action = event.actionMasked

        data class TouchValues(val fingerId: Int, val x: Float, val y: Float, val p: Float)

        fun MotionEvent.touchValues(i: Int): TouchValues {
            return TouchValues(
                    getPointerId(i),
                    getX(i) / mWidth,
                    getY(i) / mHeight,
                    // Pressure can be > 1.0 on some devices. See getPressure(i) docs.
                    min(this.getPressure(i), 1.0f)
            )
        }

        if (event.source == InputDevice.SOURCE_MOUSE && mSeparateMouseAndTouch) {
            val mouseButton = try { event.buttonState } catch (e: Exception) { 1 } // 1 is left button
            this.onNativeMouse(mouseButton, action, event.getX(0), event.getY(0))
            return true
        }

        when (action) {
            MotionEvent.ACTION_MOVE -> {
                for (i in 0 until event.pointerCount) {
                    val (fingerId, x, y, p) = event.touchValues(i)
                    this.onNativeTouch(touchDevId, fingerId, action, x, y, p)
                }
            }

            MotionEvent.ACTION_UP, MotionEvent.ACTION_DOWN -> {
                // Primary pointer up/down, the index is always zero
                val (fingerId, x, y, p) = event.touchValues(event.actionIndex)
                this.onNativeTouch(touchDevId, fingerId, action, x, y, p)
            }

            MotionEvent.ACTION_POINTER_UP, MotionEvent.ACTION_POINTER_DOWN -> {
                val (fingerId, x, y, p) = event.touchValues(event.actionIndex)
                this.onNativeTouch(touchDevId, fingerId, action, x, y, p)
            }

            MotionEvent.ACTION_CANCEL -> {
                for (i in 0 until event.pointerCount) {
                    val (fingerId, x, y, p) = event.touchValues(i)
                    this.onNativeTouch(touchDevId, fingerId, MotionEvent.ACTION_UP, x, y, p)
                }
            }
        }

        return true
    }
}