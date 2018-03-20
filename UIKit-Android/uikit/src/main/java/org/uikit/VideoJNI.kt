package org.uikit

import android.net.Uri
import android.widget.RelativeLayout
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.source.ExtractorMediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.AdaptiveTrackSelection
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import org.libsdl.app.SDLActivity
import kotlin.math.absoluteValue
import kotlin.math.roundToLong

@Suppress("unused")
class AVPlayerItem(parent: SDLActivity, url: String) {
    internal val videoSource: ExtractorMediaSource

    init {
        val regularVideoSourceUri = Uri.parse(url)

        // Produces DataSource instances through which media data is loaded.
        val dataSourceFactory = DefaultDataSourceFactory(parent.context,
                Util.getUserAgent(parent.context, "com.flowkey.uikit"))

        // ExtractorMediaSource works for regular media files such as mp4, webm, mkv
        videoSource = ExtractorMediaSource.Factory(dataSourceFactory)
                .createMediaSource(regularVideoSourceUri)
    }
}

@Suppress("unused")
class AVPlayer(parent: SDLActivity, playerItem: AVPlayerItem) {
    internal val exoPlayer: SimpleExoPlayer
    private var listener: Player.EventListener

    external fun nativeOnVideoReady()
    external fun nativeOnVideoEnded()

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

                if (!playWhenReady && playbackState == Player.STATE_ENDED) {
                    nativeOnVideoEnded()
                }
            }

            // not used but necessary to implement EventListener interface:
            override fun onSeekProcessed() {
                isSeeking = false
            }
            override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {}
            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters?) {}
            override fun onTracksChanged(trackGroups: TrackGroupArray?, trackSelections: TrackSelectionArray?) {}
            override fun onLoadingChanged(isLoading: Boolean) {}
            override fun onPositionDiscontinuity(reason: Int) {}
            override fun onRepeatModeChanged(repeatMode: Int) {}
            override fun onTimelineChanged(timeline: Timeline?, manifest: Any?, reason: Int) {}
            override fun onPlayerError(error: ExoPlaybackException?) {}
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

    fun getCurrentTimeInMilliseconds(): Double {
        return exoPlayer.currentPosition.toDouble()
    }


    private var isSeeking = false
    private var desiredSeekPosition: Double = 0.0
    private var lastSeekedToTime: Double = 0.0

    private fun seekToTimeInMilliseconds(timeInMilliseconds: Double) {
        desiredSeekPosition = timeInMilliseconds

        // This *should* mean we don't always scroll to the last position provided.
        // In practice we always seem to be at the position we want anyway:
        if (isSeeking) { return }

        // Seeking to the exact millisecond is very processor intensive (and SLOW!)
        // Only do put that effort in if we're scrubbing very slowly over a short time period:
        val syncParameters = if ((desiredSeekPosition - lastSeekedToTime).absoluteValue < 40) {
            SeekParameters.EXACT
        } else {
            SeekParameters.CLOSEST_SYNC
        }

        isSeeking = true
        exoPlayer.setSeekParameters(syncParameters)
        exoPlayer.seekTo(timeInMilliseconds.roundToLong())
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
class AVPlayerLayer(parent: SDLActivity, player: AVPlayer) {
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
}
