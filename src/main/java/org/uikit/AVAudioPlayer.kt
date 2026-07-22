package org.uikit

import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import org.libsdl.app.SDLActivity

@Suppress("unused")
class AVAudioPlayer(sdlView: SDLActivity, private val assetName: String) {
    private val context = sdlView.context
    private val mainHandler = Handler(Looper.getMainLooper())

    private var player: MediaPlayer? = null
    private var swiftInstancePtr: Long? = null
    private var volume: Float = 1.0f
    private var pendingStart: Runnable? = null

    external fun nativeOnCompletion(swiftInstancePtr: Long, success: Boolean)

    fun setSwiftInstancePtr(ptr: Long) {
        swiftInstancePtr = ptr
    }

    fun setVolume(newVolume: Double) {
        volume = newVolume.toFloat()
        player?.setVolume(volume, volume)
    }

    fun getDeviceCurrentTime(): Double = SystemClock.uptimeMillis() / 1000.0

    fun prepareToPlay(): Boolean {
        mainHandler.post {
            if (player != null) return@post
            try {
                val mp = MediaPlayer()
                context.assets.openFd(assetName).use { afd ->
                    mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                }
                mp.setVolume(volume, volume)
                mp.setOnCompletionListener { onFinished(true) }
                mp.setOnErrorListener { _, _, _ -> onFinished(false); true }
                mp.prepare()
                player = mp
            } catch (e: Exception) {
                Log.e("AVAudioPlayer", "Failed to prepare $assetName", e)
                onFinished(false)
            }
        }
        return true
    }

    fun playAtTime(timeInSeconds: Double) {
        val runnable = Runnable { player?.start() }
        pendingStart = runnable
        val targetUptimeMs = (timeInSeconds * 1000).toLong().coerceAtLeast(SystemClock.uptimeMillis())
        mainHandler.postAtTime(runnable, targetUptimeMs)
    }

    fun cleanup() {
        mainHandler.post {
            pendingStart?.let { mainHandler.removeCallbacks(it) }
            player?.release()
            player = null
        }
    }

    private fun onFinished(success: Boolean) {
        player?.release()
        player = null
        swiftInstancePtr?.let { nativeOnCompletion(it, success) }
    }
}
