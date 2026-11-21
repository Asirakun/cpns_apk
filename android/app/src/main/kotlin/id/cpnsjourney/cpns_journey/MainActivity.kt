package id.cpnsjourney.cpns_journey

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.MediaPlayer
import android.media.AudioAttributes
import android.media.AudioManager
import android.content.Context

class MainActivity : FlutterActivity() {
    private var player: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var channel: MethodChannel? = null
    private var owner: String? = null
    @Suppress("DEPRECATION")
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) stopIntro()
        if (change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) player?.setVolume(0.2f, 0.2f)
        if (change == AudioManager.AUDIOFOCUS_GAIN) player?.setVolume(1f, 1f)
    }
    @Suppress("DEPRECATION")
    private fun stopIntro() {
        player?.release()
        player = null
        owner = null
        audioManager?.abandonAudioFocus(focusListener)
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cpnsjourney/intro_audio")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "stop" -> { if (call.argument<String>("owner") == owner) stopIntro(); result.success(null) }
                "play" -> {
                    stopIntro()
                    try {
                        @Suppress("DEPRECATION")
                        val granted = audioManager?.requestAudioFocus(focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                        if (granted != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                            result.success(false)
                        } else {
                            val media = MediaPlayer()
                            player = media
                            owner = call.argument<String>("owner")
                            media.setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
                            assets.openFd("flutter_assets/assets/intro/intro-sfx.wav").use { fd -> media.setDataSource(fd.fileDescriptor, fd.startOffset, fd.length) }
                            media.setOnCompletionListener { if (player === media) stopIntro() }
                            media.setOnErrorListener { _, _, _ -> if (player === media) stopIntro(); true }
                            media.prepare()
                            val position = (call.argument<Number>("positionMs")?.toInt() ?: 0).coerceIn(0, 6666)
                            if (position > 0) media.seekTo(position)
                            media.start()
                            result.success(true)
                        }
                    } catch (_: Exception) { stopIntro(); result.success(false) }
                }
                else -> result.notImplemented()
            }
        }
    }
    override fun onPause() { stopIntro(); super.onPause() }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        stopIntro()
        channel?.setMethodCallHandler(null)
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
