package org.uikit

import android.content.Context
import android.net.Uri
import android.widget.RelativeLayout
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.database.ExoDatabaseProvider
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.FileDataSource
import androidx.media3.datasource.cache.CacheDataSink
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.SeekParameters
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.exoplayer.upstream.DefaultBandwidthMeter
import androidx.media3.ui.PlayerView
import org.libsdl.app.SDLActivity
import okhttp3.Cache as OkHttpCache
import okhttp3.OkHttpClient
import okhttp3.Protocol
import java.io.File
import java.util.concurrent.TimeUnit
import kotlin.math.absoluteValue

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

        listener = object : Player.Listener {
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
                    if (desiredSeekPosition != exoPlayer.currentPosition) {
                        seekToTimeInMilliseconds(desiredSeekPosition)
                    }
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                Log.e("SDL", "PlaybackException: ${'$'}{error.errorCodeName}")
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
        exoPlayer.setPlaybackParameters(PlaybackParameters(rate, 1.0f))
    }

    private var isSeeking = false
    private var desiredSeekPosition: Long = 0
    private var lastSeekedToTime: Long = 0

    private fun seekToTimeInMilliseconds(timeMs: Long) {
        desiredSeekPosition = timeMs
        if (isSeeking) return
        val delta = (desiredSeekPosition - lastSeekedToTime).absoluteValue
        val mode = if (delta < 250) SeekParameters.EXACT else SeekParameters.CLOSEST_SYNC
        isSeeking = true
        exoPlayer.setSeekParameters(mode)
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

/**
 * Data-source factory that wraps a single shared OkHttpClient + SimpleCache.
 */
internal class CacheDataSourceFactory(
    private val context: Context,
    private val maxCacheSize: Long,
    private val maxFileSize: Long
) : DataSource.Factory {

    init {
        // Initialize the singleton with context and cache sizes
        Media3Singleton.init(
            context = context,
            httpCacheSize = 20L * 1024 * 1024,
            mediaCacheSize = maxCacheSize
        )
    }

    private val upstreamFactory = OkHttpDataSource.Factory(Media3Singleton.okHttpClient)
    private val simpleCache = Media3Singleton.simpleCache

    override fun createDataSource(): DataSource =
        CacheDataSource(
            simpleCache,
            upstreamFactory.createDataSource(),
            FileDataSource(),
            CacheDataSink(simpleCache, maxFileSize),
            CacheDataSource.FLAG_BLOCK_ON_CACHE or CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR,
            null
        )
}

/**
 * Singleton holder for shared OkHttpClient (HTTP/2) and ExoPlayer disk cache.
 */
object Media3Singleton {
    private var initialized = false

    lateinit var okHttpClient: OkHttpClient
        private set

    lateinit var simpleCache: SimpleCache
        private set

    /**
     * Initialize once with application context and cache sizes.
     */
    fun init(context: Context, httpCacheSize: Long, mediaCacheSize: Long) {
        if (initialized) return
        initialized = true

        // ① Shared OkHttpClient with HTTP/2 support and disk cache
        val httpCacheDir = File(context.cacheDir, "http_http2_cache")
        val okCache = OkHttpCache(httpCacheDir, httpCacheSize)
        okHttpClient = OkHttpClient.Builder()
            .cache(okCache)
            .protocols(listOf(Protocol.HTTP_2, Protocol.HTTP_1_1))
            .connectTimeout(8, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .build()

        // ② Shared ExoPlayer disk cache (LRU evictor)
        val mediaCacheDir = File(context.cacheDir, "media")
        val evictor = LeastRecentlyUsedCacheEvictor(mediaCacheSize)
        simpleCache = SimpleCache(mediaCacheDir, evictor, ExoDatabaseProvider(context))
    }
}

@Suppress("unused")
class AVURLAsset(parent: SDLActivity, url: String) {
    internal val mediaSource: ProgressiveMediaSource
    private val context: Context = parent.context

    init {
        // Ensure our singletons are initialized (512 MiB cache, 20 MiB HTTP cache)
        Media3Singleton.init(
            context = context,
            httpCacheSize = 20L * 1024 * 1024,
            mediaCacheSize = 512L * 1024 * 1024
        )

        val mediaItem = MediaItem.fromUri(Uri.parse(url))
        val cacheFactory = CacheDataSourceFactory(
            context = context,
            maxCacheSize = 512L * 1024 * 1024,
            maxFileSize = 64L * 1024 * 1024
        )
        mediaSource = ProgressiveMediaSource.Factory(cacheFactory)
            .createMediaSource(mediaItem)
    }
}