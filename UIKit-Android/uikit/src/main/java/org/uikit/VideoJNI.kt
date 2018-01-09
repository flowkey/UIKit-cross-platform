package org.uikit

import android.net.Uri
import android.widget.RelativeLayout
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory
import com.google.android.exoplayer2.source.ExtractorMediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.AdaptiveTrackSelection
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout
import com.google.android.exoplayer2.ui.SimpleExoPlayerView
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import org.libsdl.app.SDLActivity

/**
 * Created by chris on 29.08.17.
 */

class VideoJNI(activity: SDLActivity, url: String) {
    private val videoPlayer: SimpleExoPlayer
    private var videoPlayerLayout: SimpleExoPlayerView? = null

    external fun nativeOnVideoEnded() // calls onVideoEnded function in Swift

    init {
        val context = activity

        val bandwidthMeter = DefaultBandwidthMeter()
        val videoTrackSelectionFactory = AdaptiveTrackSelection.Factory(bandwidthMeter)
        val trackSelector = DefaultTrackSelector(videoTrackSelectionFactory)

        videoPlayer = ExoPlayerFactory.newSimpleInstance(context, trackSelector)

        val regularVideoSourceUri = Uri.parse(url)

        // Produces DataSource instances through which media data is loaded.
        val dataSourceFactory = DefaultDataSourceFactory(context,
                Util.getUserAgent(context, "com.flowkey.nativeplayersdl"))

        // Produces Extractor instances for parsing the media data.
        val extractorsFactory = DefaultExtractorsFactory()

        // ExtractorMediaSource works for regular media files such as mp4, webm, mkv
        val videoSource = ExtractorMediaSource(regularVideoSourceUri, dataSourceFactory, extractorsFactory, null, null)
        videoPlayer.prepare(videoSource)

        videoPlayer.addListener(object: Player.EventListener {
            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                if (playbackState == Player.STATE_ENDED) {
                    nativeOnVideoEnded()
                }
            }

            // not used but necessary to implement EventListener interface:
            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters?) {}
            override fun onTracksChanged(trackGroups: TrackGroupArray?, trackSelections: TrackSelectionArray?) {}
            override fun onLoadingChanged(isLoading: Boolean) {}
            override fun onPositionDiscontinuity() {}
            override fun onRepeatModeChanged(repeatMode: Int) {}
            override fun onTimelineChanged(timeline: Timeline?, manifest: Any?) {}
            override fun onPlayerError(error: ExoPlaybackException?) {}
        })

        val videoPlayerLayout = SimpleExoPlayerView(context)
        videoPlayerLayout.player = videoPlayer
        videoPlayerLayout.useController = false

        videoPlayerLayout.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH)
        activity.mLayout?.addView(videoPlayerLayout)

        this.videoPlayerLayout = videoPlayerLayout
    }

    fun setSize(width: Int, height: Int) {
        videoPlayerLayout?.layoutParams = RelativeLayout.LayoutParams(width, height)
    }

    fun setOrigin(x: Int, y: Int) {
        videoPlayerLayout?.left = x
        videoPlayerLayout?.top = y
    }

    fun play() {
        // ExoPlayer API to play the video
        videoPlayer.playWhenReady = true
    }

    fun pause() {
        // ExoPlayer API to pause the video
        videoPlayer.playWhenReady = false
    }

    fun setVolume(newVolume: Double) {
        videoPlayer.volume = newVolume.toFloat()
    }

    fun getCurrentTimeInMilliseconds(): Double {
        return videoPlayer.currentPosition.toDouble()
    }

    fun seekToTimeInMilliseconds(timeInMilliseconds: Double) {
        videoPlayer.seekTo(timeInMilliseconds.toLong())
    }

    fun setPlaybackRate(rate: Double) {
        videoPlayer.playbackParameters = PlaybackParameters(rate.toFloat(), 1.0F)
    }
}