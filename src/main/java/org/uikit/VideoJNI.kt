package org.uikit

import android.content.Context
import android.net.Uri
import android.util.Log
import android.widget.RelativeLayout
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.database.ExoDatabaseProvider
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.*
import com.google.android.exoplayer2.upstream.cache.CacheDataSink
import com.google.android.exoplayer2.upstream.cache.CacheDataSource
import com.google.android.exoplayer2.upstream.cache.LeastRecentlyUsedCacheEvictor
import com.google.android.exoplayer2.upstream.cache.SimpleCache
import org.libsdl.app.SDLActivity
import java.io.File
import kotlin.math.absoluteValue


@Suppress("unused")
class AVURLAsset(parent: SDLActivity, url: String) {
    internal val videoSource: ProgressiveMediaSource
    private val context: Context = parent.context

    init {
        val mediaItem = MediaItem.Builder().setUri(Uri.parse(url)).build()

        // ExtractorMediaSource works for regular media files such as mp4, webm, mkv
        val cacheDataSourceFactory = CacheDataSourceFactory(
            context,
            512 * 1024 * 1024,
            64 * 1024 * 1024
        )

        videoSource = ProgressiveMediaSource
            .Factory(cacheDataSourceFactory)
            .createMediaSource(mediaItem)
    }
}

@Suppress("unused")
class AVPlayer(parent: SDLActivity, asset: AVURLAsset) {
    internal val exoPlayer: SimpleExoPlayer
    private var listener: Player.EventListener
    private var userContext: Long? = null

    external fun nativeOnVideoReady(userContext: Long)
    external fun nativeOnVideoEnded(userContext: Long)
    external fun nativeOnVideoBuffering(userContext: Long)
    external fun nativeOnVideoError(type: Int, message: String, userContext: Long)

    init {
        val bandwidthMeter = DefaultBandwidthMeter.Builder(parent.context).build()
        val trackSelector = DefaultTrackSelector(parent.context)
        
        exoPlayer = SimpleExoPlayer.Builder(parent.context)
                .setBandwidthMeter(bandwidthMeter)
                .setTrackSelector(trackSelector)
                .build()
        exoPlayer.prepare()
        exoPlayer.setMediaSource(asset.videoSource)

        listener = object: Player.EventListener {
            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                this@AVPlayer.userContext?.let { userContext ->
                    when (playbackState) {
                        Player.STATE_READY -> nativeOnVideoReady(userContext)
                        Player.STATE_ENDED -> nativeOnVideoEnded(userContext)
                        Player.STATE_BUFFERING -> nativeOnVideoBuffering(userContext)
                        else -> {}
                    }
                }
            }

            override fun onSeekProcessed() {
                isSeeking = false
                if (desiredSeekPosition != getCurrentTimeInMilliseconds()) {
                    seekToTimeInMilliseconds(desiredSeekPosition)
                }
            }

            override fun onPlayerError(error: ExoPlaybackException) {
                this@AVPlayer.userContext?.let { userContext ->
                    Log.e("SDL", "ExoPlaybackException occurred")
                    val message = error.message ?: "unknown"
                    nativeOnVideoError(error.type, message, userContext)
                }
            }
        }

        exoPlayer.addListener(listener)
    }

    fun setUserContext(ctx: Long) {
        this.userContext = ctx
    }

    fun play() {
        // ExoPlayer API to play the video
        exoPlayer.playWhenReady = true
    }

    fun pause() {
        // ExoPlayer API to pause the video
        exoPlayer.playWhenReady = false
    }

    fun setVolume(newVolume: Double) {
        exoPlayer.volume = newVolume.toFloat()
    }

    fun getCurrentTimeInMilliseconds(): Long {
        return exoPlayer.currentPosition
    }


    private var isSeeking = false
    private var desiredSeekPosition: Long = 0
    private var lastSeekedToTime: Long = 0

    private fun seekToTimeInMilliseconds(timeInMilliseconds: Long) {
        desiredSeekPosition = timeInMilliseconds

        // This *should* mean we don't always scroll to the last position provided.
        // In practice we always seem to be at the position we want anyway:
        if (isSeeking) { return }

        // Seeking to the exact millisecond is very processor intensive (and SLOW!)
        // Only do put that effort in if we're scrubbing very slowly over a short time period:
        val syncParameters = if ((desiredSeekPosition - lastSeekedToTime).absoluteValue < 250) {
            SeekParameters.EXACT
        } else {
            SeekParameters.CLOSEST_SYNC
        }

        isSeeking = true
        exoPlayer.setSeekParameters(syncParameters)
        exoPlayer.seekTo(timeInMilliseconds)
        lastSeekedToTime = timeInMilliseconds
    }

    fun getPlaybackRate(): Float {
        return exoPlayer.playbackParameters.speed
    }

    fun setPlaybackRate(rate: Float) {
        exoPlayer.setPlaybackParameters(PlaybackParameters(rate, 1.0F))
    }

    fun cleanup() {
        exoPlayer.removeListener(listener)
        exoPlayer.release()
    }
}

@Suppress("unused")
class AVPlayerLayer(private val parent: SDLActivity, player: AVPlayer) {
    private var exoPlayerLayout: PlayerView

    init {
        val context = parent.context

        exoPlayerLayout = PlayerView(context)
        exoPlayerLayout.player = player.exoPlayer
        exoPlayerLayout.useController = false
        exoPlayerLayout.tag = "ExoPlayer"
        parent.addView(exoPlayerLayout, 0)
    }

    fun setFrame(x: Int, y: Int, width: Int, height: Int) {
        val layoutParams = RelativeLayout.LayoutParams(width, height)
        layoutParams.setMargins(x, y, 0, 0)
        exoPlayerLayout.layoutParams = layoutParams
    }

    fun setResizeMode(resizeMode: Int) {
        exoPlayerLayout.resizeMode = resizeMode
    }

    fun removeFromParent() {
        Log.v("SDL", "Removing video from parent layout")
        parent.removeViewInLayout(exoPlayerLayout)
    }
}




///// Caching data source
// Thank you https://stackoverflow.com/a/45488510/3086440

private class CacheDataSourceFactory(private val context: Context, private val maxCacheSize: Long, private val maxFileSize: Long) : DataSource.Factory {

    private val defaultDatasourceFactory: DefaultDataSourceFactory

    // The cache survives the application lifetime, otherwise the cache keys can get confused
    companion object {
        var simpleCache: SimpleCache? = null
    }

    init {
        val bandwidthMeter = DefaultBandwidthMeter.Builder(context).build()
        defaultDatasourceFactory = DefaultDataSourceFactory(this.context,
                bandwidthMeter, DefaultHttpDataSource.Factory())
    }

    override fun createDataSource(): DataSource {
        if (simpleCache == null) {
            val cacheEvictor = LeastRecentlyUsedCacheEvictor(maxCacheSize)
            val dataBaseProvider = ExoDatabaseProvider(context)
            val file = File(context.cacheDir, "media")
            simpleCache = SimpleCache(file, cacheEvictor, dataBaseProvider)
        }

        return CacheDataSource(simpleCache!!, defaultDatasourceFactory.createDataSource(),
                FileDataSource(), CacheDataSink(simpleCache!!, maxFileSize),
                CacheDataSource.FLAG_BLOCK_ON_CACHE or CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR, null)
    }
}