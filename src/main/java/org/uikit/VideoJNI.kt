package org.uikit

import android.net.Uri
import android.util.Log
import android.widget.RelativeLayout
import android.content.Context
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.source.ExtractorMediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.AdaptiveTrackSelection
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.*
import com.google.android.exoplayer2.util.Util
import org.libsdl.app.SDLActivity
import kotlin.math.absoluteValue
import com.google.android.exoplayer2.upstream.cache.CacheDataSource
import com.google.android.exoplayer2.upstream.cache.CacheDataSink
import com.google.android.exoplayer2.upstream.cache.SimpleCache
import com.google.android.exoplayer2.upstream.cache.LeastRecentlyUsedCacheEvictor
import java.io.File


@Suppress("unused")
class AVPlayerItem(parent: SDLActivity, url: String) {
    internal val videoSource: ExtractorMediaSource

    init {
        val videoSourceUri = Uri.parse(url)

        // ExtractorMediaSource works for regular media files such as mp4, webm, mkv
        val cacheDataSourceFactory = CacheDataSourceFactory(
                parent.context,
                256 * 1024 * 1024,
                32 * 1024 * 1024
        )

        videoSource = ExtractorMediaSource
                        .Factory(cacheDataSourceFactory)
                        .createMediaSource(videoSourceUri)
    }
}

@Suppress("unused")
class AVPlayer(parent: SDLActivity, playerItem: AVPlayerItem) {
    internal val exoPlayer: SimpleExoPlayer
    private var listener: Player.EventListener

    external fun nativeOnVideoReady()
    external fun nativeOnVideoEnded()
    external fun nativeOnVideoSourceError()

    init {
        val bandwidthMeter = DefaultBandwidthMeter()
        val videoTrackSelectionFactory = AdaptiveTrackSelection.Factory(bandwidthMeter)
        val trackSelector = DefaultTrackSelector(videoTrackSelectionFactory)

        exoPlayer = ExoPlayerFactory.newSimpleInstance(parent.context, trackSelector)
        exoPlayer.prepare(playerItem.videoSource)

        listener = object: Player.EventListener {
            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                if (playbackState == Player.STATE_READY) {
                    nativeOnVideoReady()
                }

                if (playbackState == Player.STATE_ENDED) {
                    nativeOnVideoEnded()
                }
            }

            override fun onSeekProcessed() {
                isSeeking = false
                if (desiredSeekPosition != getCurrentTimeInMilliseconds()) {
                    seekToTimeInMilliseconds(desiredSeekPosition)
                }
            }

            override fun onPlayerError(error: ExoPlaybackException?) {
                if (error?.type == ExoPlaybackException.TYPE_SOURCE) {
                    nativeOnVideoSourceError()
                    Log.e("SDL", "ExoPlaybackException occurred")
                }
            }

            // not used but necessary to implement EventListener interface:
            override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {}
            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters?) {}
            override fun onTracksChanged(trackGroups: TrackGroupArray?, trackSelections: TrackSelectionArray?) {}
            override fun onLoadingChanged(isLoading: Boolean) {}
            override fun onPositionDiscontinuity(reason: Int) {}
            override fun onRepeatModeChanged(repeatMode: Int) {}
            override fun onTimelineChanged(timeline: Timeline?, manifest: Any?, reason: Int) {}
        }

        exoPlayer.addListener(listener)
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
        exoPlayer.playbackParameters = PlaybackParameters(rate, 1.0F)
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
        exoPlayerLayout.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH)

        parent.addView(exoPlayerLayout, 0)
    }

    fun setFrame(x: Int, y: Int, width: Int, height: Int) {
        val layoutParams = RelativeLayout.LayoutParams(width, height)
        layoutParams.setMargins(x, y, 0, 0)
        exoPlayerLayout.layoutParams = layoutParams
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
        val userAgent = Util.getUserAgent(context, "com.flowkey.VideoJNI")
        val bandwidthMeter = DefaultBandwidthMeter()
        defaultDatasourceFactory = DefaultDataSourceFactory(this.context,
                bandwidthMeter,
                DefaultHttpDataSourceFactory(userAgent, bandwidthMeter))
    }

    override fun createDataSource(): DataSource {
        if (simpleCache == null) {
            val evictor = LeastRecentlyUsedCacheEvictor(maxCacheSize)
            simpleCache = SimpleCache(File(context.cacheDir, "media"), evictor)
        }

        return CacheDataSource(simpleCache, defaultDatasourceFactory.createDataSource(),
                FileDataSource(), CacheDataSink(simpleCache, maxFileSize),
                CacheDataSource.FLAG_BLOCK_ON_CACHE or CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR, null)
    }
}