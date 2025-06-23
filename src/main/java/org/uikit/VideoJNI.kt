package org.uikit

import android.content.Context
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import org.libsdl.app.SDLActivity
import androidx.media3.database.ExoDatabaseProvider
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.FileDataSource
import androidx.media3.datasource.cache.CacheDataSink
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import java.io.File
import android.widget.RelativeLayout
import android.util.Log
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.SeekParameters
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.exoplayer.upstream.DefaultBandwidthMeter
import androidx.media3.ui.PlayerView
import kotlin.math.absoluteValue

@Suppress("unused")
class AVURLAsset(parent: SDLActivity, url: String) {
    internal val mediaSource: ProgressiveMediaSource
    private val context: Context = parent.context

    init {
        val mediaItem = MediaItem.Builder()
            .setUri(Uri.parse(url))
            .build()

        // 512 MiB total cache, individual file parts ≤ 64 MiB
        val cacheFactory = CacheDataSourceFactory(
            context,
            maxCacheSize = 512L * 1024 * 1024,
            maxFileSize = 64L * 1024 * 1024
        )

        mediaSource = ProgressiveMediaSource
            .Factory(cacheFactory)
            .createMediaSource(mediaItem)
    }
}

@Suppress("unused")
class AVPlayer(parent: SDLActivity, asset: AVURLAsset) {
    internal val exoPlayer: ExoPlayer
    private val listener: Player.Listener

    external fun nativeOnVideoReady()
    external fun nativeOnVideoEnded()
    external fun nativeOnVideoBuffering()
    external fun nativeOnVideoError(type: Int, message: String)

    init {
        val bandwidthMeter = DefaultBandwidthMeter.Builder(parent.context).build()
        val trackSelector = DefaultTrackSelector(parent.context)

        exoPlayer = ExoPlayer.Builder(parent.context)
            .setBandwidthMeter(bandwidthMeter)
            .setTrackSelector(trackSelector)
            .build().apply {
                setMediaSource(asset.mediaSource)
                prepare()
            }

        listener = object: Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                when (state) {
                    Player.STATE_READY -> nativeOnVideoReady()
                    Player.STATE_BUFFERING -> nativeOnVideoBuffering()
                    Player.STATE_ENDED -> nativeOnVideoEnded()
                }
            }

            override fun onPositionDiscontinuity(
                oldPosition: Player.PositionInfo,
                newPosition: Player.PositionInfo,
                reason: Int
            ) {
                if (reason == Player.DISCONTINUITY_REASON_SEEK) {
                    isSeeking = false
                    if (desiredSeekPosition != getCurrentTimeInMilliseconds()) {
                        seekToTimeInMilliseconds(desiredSeekPosition)
                    }
                }
            }

            override fun onPlayerError(error: PlaybackException) {   // PlaybackException replaces ExoPlaybackException :contentReference[oaicite:1]{index=1}
                Log.e("SDL", "PlaybackException: ${error.errorCodeName}")
                nativeOnVideoError(error.errorCode, error.message ?: "N/A")
            }
        }

        exoPlayer.addListener(listener)
    }

    fun play() {
        exoPlayer.playWhenReady = true
    }

    fun pause() {
        exoPlayer.playWhenReady = false
    }

    fun setVolume(newVolume: Double) {
        exoPlayer.volume = newVolume.toFloat()
    }

    fun getCurrentTimeInMilliseconds(): Long = exoPlayer.currentPosition

    fun getPlaybackRate(): Float = exoPlayer.playbackParameters.speed
    fun setPlaybackRate(rate: Float) {
        exoPlayer.setPlaybackParameters(PlaybackParameters(rate, /*pitch*/1.0f))
    }

    private var isSeeking = false
    private var desiredSeekPosition: Long = 0
    private var lastSeekedToTime: Long = 0

    private fun seekToTimeInMilliseconds(timeMs: Long) {
        desiredSeekPosition = timeMs

        // This *should* mean we don't always scroll to the last position provided.
        // In practice we always seem to be at the position we want anyway:
        if (isSeeking) return

        // Seeking to the exact millisecond is very processor intensive (and SLOW!)
        // Only do put that effort in if we're scrubbing very slowly over a short time period:
        val seekParameters = if ((desiredSeekPosition - lastSeekedToTime).absoluteValue < 250) {
            SeekParameters.EXACT
        } else {
            SeekParameters.CLOSEST_SYNC
        }

        isSeeking = true
        exoPlayer.setSeekParameters(seekParameters)
        exoPlayer.seekTo(timeMs)
        lastSeekedToTime = timeMs
    }

    fun cleanup() {
        exoPlayer.removeListener(listener)
        exoPlayer.release()
    }
}

@Suppress("unused")
class AVPlayerLayer(private val parent: SDLActivity, player: AVPlayer) {
    private val exoPlayerView: PlayerView = PlayerView(parent.context).apply {
        useController = false
        tag = "ExoPlayer"
        this.player = player.exoPlayer
    }

    init {
        parent.addView(exoPlayerView, 0)
    }

    fun setFrame(x: Int, y: Int, width: Int, height: Int) {
        exoPlayerView.layoutParams = RelativeLayout.LayoutParams(width, height).also {
            it.setMargins(x, y, 0, 0)
        }
    }

    fun setResizeMode(resizeMode: Int) {
        exoPlayerView.resizeMode = resizeMode
    }

    fun removeFromParent() = parent.removeViewInLayout(exoPlayerView)
}

// Data‑source factory that adds a read/write LRU cache around HTTP & file accesses
internal class CacheDataSourceFactory(
    private val context: Context,
    private val maxCacheSize: Long,
    private val maxFileSize: Long
) : DataSource.Factory {
    private val upstreamFactory = DefaultDataSource.Factory(context)

    private val simpleCache by lazy {
        val cacheDir = File(context.cacheDir, "media")
        SimpleCache(
            cacheDir,
            LeastRecentlyUsedCacheEvictor(maxCacheSize),
            ExoDatabaseProvider(context)
        )
    }

    override fun createDataSource(): DataSource =
        CacheDataSource(
            simpleCache,
            upstreamFactory.createDataSource(),
            FileDataSource(),
            CacheDataSink(simpleCache, maxFileSize),
            CacheDataSource.FLAG_BLOCK_ON_CACHE or
                    CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR,
            null
        )
}
