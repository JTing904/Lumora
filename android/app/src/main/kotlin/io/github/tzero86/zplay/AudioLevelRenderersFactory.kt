package io.github.tzero86.zplay

import android.content.Context
import android.media.MediaFormat
import android.os.Build
import android.os.Handler
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.Renderer
import androidx.media3.exoplayer.audio.AudioRendererEventListener
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.MediaCodecAudioRenderer
import androidx.media3.exoplayer.mediacodec.MediaCodecAdapter
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector
import java.nio.ByteBuffer

/**
 * The stock renderers, except that the audio one also shows [tap] the PCM it
 * decodes.
 *
 * An AudioProcessor in the sink would see the same samples, but it sees them
 * without timestamps, so the film time of each would have to be rebuilt from a
 * counter that a seek or a dropped buffer throws off. The renderer is handed
 * the decoder's presentation timestamp with every buffer, which is the time
 * the subtitle sync needs.
 */
@UnstableApi
class AudioLevelRenderersFactory(
    context: Context,
    private val tap: AudioLevelTap
) : DefaultRenderersFactory(context) {

    override fun buildAudioRenderers(
        context: Context,
        extensionRendererMode: Int,
        mediaCodecSelector: MediaCodecSelector,
        enableDecoderFallback: Boolean,
        audioSink: AudioSink,
        eventHandler: Handler,
        eventListener: AudioRendererEventListener,
        out: ArrayList<Renderer>
    ) {
        super.buildAudioRenderers(
            context,
            extensionRendererMode,
            mediaCodecSelector,
            enableDecoderFallback,
            audioSink,
            eventHandler,
            eventListener,
            out
        )
        // Swapped in place rather than built from scratch, so the order of any
        // extension renderers stays the default's.
        val index = out.indexOfFirst { it.javaClass == MediaCodecAudioRenderer::class.java }
        if (index < 0) return
        out[index] = LevelMeasuringAudioRenderer(
            context,
            codecAdapterFactory,
            mediaCodecSelector,
            enableDecoderFallback,
            eventHandler,
            eventListener,
            audioSink,
            tap
        )
    }
}

@UnstableApi
private class LevelMeasuringAudioRenderer(
    context: Context,
    codecAdapterFactory: MediaCodecAdapter.Factory,
    mediaCodecSelector: MediaCodecSelector,
    enableDecoderFallback: Boolean,
    eventHandler: Handler,
    eventListener: AudioRendererEventListener,
    audioSink: AudioSink,
    private val tap: AudioLevelTap
) : MediaCodecAudioRenderer(
    context,
    codecAdapterFactory,
    mediaCodecSelector,
    enableDecoderFallback,
    eventHandler,
    eventListener,
    audioSink
) {

    override fun onOutputFormatChanged(format: Format, mediaFormat: MediaFormat?) {
        super.onOutputFormatChanged(format, mediaFormat)
        // The codec's own output format, not the track's: a compressed track's
        // Format says nothing of the PCM that comes out. A null one means the
        // codec is bypassed (passthrough), where the buffers are not PCM at all.
        if (mediaFormat == null ||
            !mediaFormat.containsKey(MediaFormat.KEY_SAMPLE_RATE) ||
            !mediaFormat.containsKey(MediaFormat.KEY_CHANNEL_COUNT)
        ) {
            tap.onFormat(0, 0, C.ENCODING_INVALID)
            return
        }
        val encoding =
            if (Build.VERSION.SDK_INT >= 24 && mediaFormat.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                mediaFormat.getInteger(MediaFormat.KEY_PCM_ENCODING)
            } else {
                C.ENCODING_PCM_16BIT
            }
        tap.onFormat(
            mediaFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE),
            mediaFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT),
            encoding
        )
    }

    override fun onPositionReset(
        positionUs: Long,
        joining: Boolean,
        sampleStreamIsResetToKeyFrame: Boolean
    ) {
        super.onPositionReset(positionUs, joining, sampleStreamIsResetToKeyFrame)
        tap.onDiscontinuity()
    }

    override fun onProcessedStreamChange() {
        super.onProcessedStreamChange()
        tap.onDiscontinuity()
    }

    override fun onDisabled() {
        super.onDisabled()
        tap.onDiscontinuity()
    }

    override fun processOutputBuffer(
        positionUs: Long,
        elapsedRealtimeUs: Long,
        codec: MediaCodecAdapter?,
        buffer: ByteBuffer?,
        bufferIndex: Int,
        bufferFlags: Int,
        sampleCount: Int,
        bufferPresentationTimeUs: Long,
        isDecodeOnlyBuffer: Boolean,
        isLastBuffer: Boolean,
        format: Format
    ): Boolean {
        // Measured before the sink takes it, since the sink advances the
        // buffer's position. A decode-only buffer is one the renderer throws
        // away (the run-up after a seek), so nobody hears it.
        if (buffer != null && codec != null && !isDecodeOnlyBuffer && buffer.hasRemaining()) {
            tap.onBuffer(buffer, bufferIndex, bufferPresentationTimeUs, outputStreamOffsetUs)
        }
        return super.processOutputBuffer(
            positionUs,
            elapsedRealtimeUs,
            codec,
            buffer,
            bufferIndex,
            bufferFlags,
            sampleCount,
            bufferPresentationTimeUs,
            isDecodeOnlyBuffer,
            isLastBuffer,
            format
        )
    }
}
