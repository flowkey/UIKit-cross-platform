package org.uikit

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
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
import androidx.media3.ui.PlayerView
import org.libsdl.app.SDLActivity
import okhttp3.Cache as OkHttpCache
import okhttp3.OkHttpClient
import okhttp3.Protocol
import java.io.File
import kotlin.math.absoluteValue

@Suppress("unused")
class AVPlayer(sdlView: SDLActivity, asset: AVURLAsset) {
    private val mediaSourceFactory =
        androidx.media3.exoplayer.source.DefaultMediaSourceFactory(sdlView.context)
            .setDataSourceFactory(CacheDataSourceFactory(maxFileSize = 256L * 1024 * 1024))

    internal val exoPlayer: ExoPlayer = ExoPlayer.Builder(sdlView.context)
        .setMediaSourceFactory(mediaSourceFactory)
        .build().apply {
            setMediaItem(asset.mediaItem)
            prepare()
        }

    private val listener: Player.Listener
    private var swiftAVPlayerInstancePtr: Long? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingSeek: Runnable? = null

    external fun nativeOnVideoReady(swiftAVPlayerInstancePtr: Long)
    external fun nativeOnVideoEnded(swiftAVPlayerInstancePtr: Long)
    external fun nativeOnVideoBuffering(swiftAVPlayerInstancePtr: Long)
    external fun nativeOnVideoError(type: Int, message: String, swiftAVPlayerInstancePtr: Long)

    init {
        listener = object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                this@AVPlayer.swiftAVPlayerInstancePtr?.let { context ->
                    when (state) {
                        Player.STATE_READY     -> nativeOnVideoReady(context)
                        Player.STATE_BUFFERING -> nativeOnVideoBuffering(context)
                        Player.STATE_ENDED     -> nativeOnVideoEnded(context)
                        else -> {}
                    }
                }
            }

            override fun onPositionDiscontinuity(
                oldPosition: Player.PositionInfo,
                newPosition: Player.PositionInfo,
                reason: Int
            ) {
                if (reason == Player.DISCONTINUITY_REASON_SEEK) {
                    isSeeking = false
                    val delta = (newPosition.positionMs - desiredSeekPosition).absoluteValue
                    if (delta > 50) {
                        // debounce/cancel any in-flight correction
                        pendingSeek?.let { mainHandler.removeCallbacks(it) }
                        // schedule a corrective seek
                        pendingSeek = Runnable { doSeekSync(desiredSeekPosition) }
                        mainHandler.post(pendingSeek!!)
                    }
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                this@AVPlayer.swiftAVPlayerInstancePtr?.let { swiftAVPlayerInstancePtr ->
                    Log.e("SDL", "ExoPlaybackException occurred")
                    val message = error.message ?: "unknown"
                    Log.e("SDL", message)
                    nativeOnVideoError(error.errorCode, message, swiftAVPlayerInstancePtr)
                }
            }
        }

        exoPlayer.addListener(listener)
    }

    fun setSwiftAVPlayerInstancePtr(ptr: Long) {
        this.swiftAVPlayerInstancePtr = ptr
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
        exoPlayer.playbackParameters = PlaybackParameters(rate, 1.0f)
    }

    private var isSeeking = false
    private var desiredSeekPosition: Long = 0
    private var lastSeekedToTime: Long = 0

    fun seekToTimeInMilliseconds(timeMs: Long) {
        desiredSeekPosition = timeMs

        // debounce any previous seek attempts
        pendingSeek?.let { mainHandler.removeCallbacks(it) }

        // schedule the new seek on the main thread
        pendingSeek = Runnable { doSeekSync(timeMs) }
        mainHandler.post(pendingSeek!!)
    }

    private fun doSeekSync(timeMs: Long) {
        if (isSeeking) return

        val deltaTotal = (timeMs - lastSeekedToTime).absoluteValue
        val params = if (deltaTotal < 100) SeekParameters.EXACT else SeekParameters.CLOSEST_SYNC
        exoPlayer.setSeekParameters(params)

        isSeeking = true
        exoPlayer.seekTo(timeMs)
        lastSeekedToTime = timeMs
    }

    fun cleanup() {
        pendingSeek?.let { mainHandler.removeCallbacks(it) }
        exoPlayer.removeListener(listener)
        exoPlayer.release()
    }
}

@Suppress("unused")
class AVPlayerLayer(private val sdlView: SDLActivity, player: AVPlayer) {
    private val exoPlayerView: PlayerView = PlayerView(sdlView.context).apply {
        useController = false
        tag = "ExoPlayer"
        this.player = player.exoPlayer
    }

    init {
        sdlView.addView(exoPlayerView, 0)
    }

    fun setFrame(x: Int, y: Int, width: Int, height: Int) {
        exoPlayerView.layoutParams = RelativeLayout.LayoutParams(width, height).also {
            it.setMargins(x, y, 0, 0)
        }
    }

    fun setResizeMode(resizeMode: Int) {
        exoPlayerView.resizeMode = resizeMode
    }

    fun removeFromParent() = sdlView.removeViewInLayout(exoPlayerView)
}

/**
 * Data-source factory that reuses the singleton cache and HTTP client.
 */
internal class CacheDataSourceFactory(private val maxFileSize: Long): DataSource.Factory {
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
    lateinit var okHttpClient: OkHttpClient private set
    lateinit var simpleCache: SimpleCache private set

    /**
     * Initialize once with application context and cache sizes.
     */
    fun init(context: Context, httpCacheSize: Long, mediaCacheSize: Long) {
        if (initialized) return
        initialized = true

        // 1. Shared OkHttpClient with HTTP/2 support and disk cache
        val httpCacheDir = File(context.cacheDir, "http_http2_cache")
        val okCache = OkHttpCache(httpCacheDir, httpCacheSize)
        okHttpClient = OkHttpClient.Builder()
            .cache(okCache)
            .protocols(listOf(Protocol.HTTP_2, Protocol.HTTP_1_1))
            .build()

        // 2. Shared ExoPlayer disk cache (LRU evictor)
        val mediaCacheDir = File(context.cacheDir, "media")
        val evictor = LeastRecentlyUsedCacheEvictor(mediaCacheSize)
        simpleCache = SimpleCache(mediaCacheDir, evictor, ExoDatabaseProvider(context))
    }
}

@Suppress("unused")
class AVURLAsset(sdlView: SDLActivity, url: String) {
    internal val mediaItem: MediaItem
    private val context: Context = sdlView.context

    init {
        Media3Singleton.init(
            context = context,
            httpCacheSize = 20L * 1024 * 1024,
            mediaCacheSize = 512L * 1024 * 1024
        )

        mediaItem = MediaItem.Builder()
            .setUri(Uri.parse(url))
            // .setMimeType("video/mp4") // optional; omit unless you're sure every URL is MP4
            .build()
    }
}