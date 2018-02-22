package main.java.org.libsdl.app

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Display
import android.view.Surface

/**
 * Created by erik on 22.02.18.
 */
interface SDLSensorEventListener: SensorEventListener {

    fun onNativeAccel(x: Float, y: Float, z: Float)

    val rotation: Int

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        // TODO
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return

        val x: Float
        val y: Float
        when (rotation) {
            Surface.ROTATION_90 -> {
                x = -event.values[1]
                y = event.values[0]
            }
            Surface.ROTATION_270 -> {
                x = event.values[1]
                y = -event.values[0]
            }
            Surface.ROTATION_180 -> {
                x = -event.values[1]
                y = -event.values[0]
            }
            else -> {
                x = event.values[0]
                y = event.values[1]
            }
        }

        onNativeAccel(
                -x / SensorManager.GRAVITY_EARTH,
                y / SensorManager.GRAVITY_EARTH,
                event.values[2] / SensorManager.GRAVITY_EARTH
        )
    }
}