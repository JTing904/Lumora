package io.github.tzero86.zplay

import android.os.Handler
import android.os.Looper
import androidx.media3.common.C
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.sqrt

/**
 * How loud the speech band of a film's audio is, one figure per tenth of a
 * second of film.
 *
 * The subtitle auto-sync compares these against when subtitles say people are
 * talking, so each figure carries the time in the film where its stretch plays
 * (the decoder's presentation timestamp), never the time it was measured. The
 * audio sink buffers a few hundred milliseconds before a speaker sounds, so a
 * figure stamped with the player's position when it was computed would lean
 * late by exactly that much.
 *
 * Runs on the playback thread, on buffers the decoder has already produced.
 * Nothing here writes to them.
 */
class AudioLevelMeter(private val onWindow: (timeSec: Double, db: Double) -> Unit) {

    private companion object {
        const val STEP_SEC = 0.1

        // The band speech lives in. Below it is rumble and the LFE channel,
        // above it hiss and cymbals.
        const val HIGH_PASS_HZ = 200.0
        const val LOW_PASS_HZ = 3500.0

        /**
         * A buffer starting further than this from where the last one ended means
         * the audio jumped (a seek the player did not report as one, an ad
         * boundary, a dropped stretch). Measuring across the jump would stamp
         * the window with the wrong time.
         */
        const val GAP_TOLERANCE_SEC = 0.05

        const val FLOOR_DB = -120.0
    }

    private var sampleRate = 0
    private var encoding = C.ENCODING_INVALID
    private var bytesPerSample = 0
    private var frameBytes = 0

    // How many of the leading channels are mixed down; see [configure].
    private var mixChannels = 0
    private var windowFrames = 0
    private var highPassCoef = 0.0
    private var lowPassCoef = 0.0

    private var anchored = false
    private var expectedSec = 0.0
    private var windowStartSec = 0.0
    private var windowCount = 0
    private var windowSumSq = 0.0

    private var highPassIn = 0.0
    private var highPassOut = 0.0
    private var lowPassOut = 0.0

    /**
     * Sets the format of the PCM that follows. Returns false for one this meter
     * does not read (compressed passthrough, 8-bit), after which [process] does
     * nothing until a readable format arrives.
     */
    fun configure(sampleRate: Int, channelCount: Int, pcmEncoding: Int): Boolean {
        reset()
        bytesPerSample = when (pcmEncoding) {
            C.ENCODING_PCM_16BIT -> 2
            C.ENCODING_PCM_24BIT -> 3
            C.ENCODING_PCM_32BIT, C.ENCODING_PCM_FLOAT -> 4
            else -> 0
        }
        if (bytesPerSample == 0 || sampleRate <= 0 || channelCount <= 0) {
            this.sampleRate = 0
            return false
        }
        this.sampleRate = sampleRate
        encoding = pcmEncoding
        frameBytes = bytesPerSample * channelCount
        // Android lays channels out front-left, front-right, front-centre, ... so
        // the first three hold the dialogue in stereo, 5.1 and 7.1 alike. The
        // LFE and surrounds only add music and effects that blur speech.
        mixChannels = minOf(channelCount, 3)
        windowFrames = maxOf(1, (sampleRate * STEP_SEC).toInt())

        // One-pole filters: cheap, and a gentle slope is enough for telling
        // speech from silence and from a film's score.
        val dt = 1.0 / sampleRate
        val highPassRc = 1.0 / (2.0 * PI * HIGH_PASS_HZ)
        val lowPassRc = 1.0 / (2.0 * PI * LOW_PASS_HZ)
        highPassCoef = highPassRc / (highPassRc + dt)
        lowPassCoef = dt / (lowPassRc + dt)
        return true
    }

    /** Forgets the window in progress, the filter memory and where the last buffer ended. */
    fun reset() {
        anchored = false
        windowCount = 0
        windowSumSq = 0.0
        highPassIn = 0.0
        highPassOut = 0.0
        lowPassOut = 0.0
    }

    /**
     * Measures the bytes between [buffer]'s position and limit, whose first
     * frame plays at [ptsSec] in the film. Reads through its own view, so the
     * caller's buffer keeps its position and goes on to the speaker untouched.
     */
    fun process(buffer: ByteBuffer, ptsSec: Double) {
        if (sampleRate == 0) return
        val start = buffer.position()
        val frames = (buffer.limit() - start) / frameBytes
        if (frames <= 0) return

        if (!anchored || abs(ptsSec - expectedSec) > GAP_TOLERANCE_SEC) {
            // Whatever is half-measured belongs to a stretch that ended; the
            // filters would also ring on the step between the two.
            reset()
            anchored = true
        }

        val view = buffer.duplicate().order(ByteOrder.nativeOrder())
        for (frame in 0 until frames) {
            val index = start + frame * frameBytes
            var mixed = 0.0
            for (c in 0 until mixChannels) {
                mixed += sampleAt(view, index + c * bytesPerSample)
            }
            val x = mixed / mixChannels

            val high = highPassCoef * (highPassOut + x - highPassIn)
            highPassIn = x
            highPassOut = high
            lowPassOut += lowPassCoef * (high - lowPassOut)

            if (windowCount == 0) windowStartSec = ptsSec + frame.toDouble() / sampleRate
            windowSumSq += lowPassOut * lowPassOut
            windowCount++
            if (windowCount == windowFrames) {
                val rms = sqrt(windowSumSq / windowCount)
                val db = if (rms < 1e-6) FLOOR_DB else maxOf(FLOOR_DB, 20.0 * log10(rms))
                onWindow(windowStartSec, db)
                windowCount = 0
                windowSumSq = 0.0
            }
        }
        expectedSec = ptsSec + frames.toDouble() / sampleRate
    }

    /** One sample as a fraction of full scale, read by absolute index so the buffer is not consumed. */
    private fun sampleAt(view: ByteBuffer, index: Int): Double = when (encoding) {
        C.ENCODING_PCM_16BIT -> view.getShort(index) / 32768.0
        C.ENCODING_PCM_FLOAT -> view.getFloat(index).toDouble()
        C.ENCODING_PCM_32BIT -> view.getInt(index) / 2147483648.0
        else -> {
            // 24-bit packed, little-endian.
            val v = (view.get(index).toInt() and 0xFF) or
                ((view.get(index + 1).toInt() and 0xFF) shl 8) or
                (view.get(index + 2).toInt() shl 16)
            v / 8388608.0
        }
    }
}

/**
 * Sits between the decoder and the event channel: runs [AudioLevelMeter] while
 * the Dart side wants levels, and sends what it measures in batches.
 *
 * Off by default and free while off: the renderer's hook is one volatile read
 * per decoded buffer. Lives as long as the bridge, not the player, because
 * every load builds a new player and the Dart subscription does not follow it.
 */
class AudioLevelTap(private val deliver: (Map<String, Any?>) -> Unit) {

    private companion object {
        // A few batches a second keeps the channel quiet.
        const val FLUSH_MS = 300L
    }

    @Volatile
    private var enabled = false

    /**
     * Set from the main thread, honoured by the playback thread: the meter is
     * only ever touched by one thread, so enabling and seeking go through a
     * flag rather than reaching into it.
     */
    @Volatile
    private var resetRequested = false

    private val meter = AudioLevelMeter(::onWindow)
    private var lastIndex = -1
    private var lastPtsUs = Long.MIN_VALUE

    private val lock = Any()
    private val times = ArrayList<Double>()
    private val levels = ArrayList<Double>()
    private var flushScheduled = false
    private val main = Handler(Looper.getMainLooper())
    private val flush = Runnable { sendBatch() }

    fun setEnabled(on: Boolean) {
        if (on == enabled) return
        if (on) resetRequested = true
        enabled = on
        if (!on) clearPending()
    }

    /** Drops what is measured but not yet sent, and starts the next buffer fresh. */
    fun clear() {
        resetRequested = true
        clearPending()
    }

    /** Playback thread. The decoder has been flushed or its stream replaced. */
    fun onDiscontinuity() = clear()

    /** Playback thread. The format of the PCM that follows; always called, so enabling mid-film already knows it. */
    fun onFormat(sampleRate: Int, channelCount: Int, pcmEncoding: Int) {
        meter.configure(sampleRate, channelCount, pcmEncoding)
        lastIndex = -1
        lastPtsUs = Long.MIN_VALUE
    }

    /**
     * Playback thread. [ptsUs] is the buffer's timestamp in the renderer's
     * timeline and [offsetUs] the offset that timeline adds to the film's, so
     * their difference is where in the film the buffer plays.
     */
    fun onBuffer(buffer: ByteBuffer, bufferIndex: Int, ptsUs: Long, offsetUs: Long) {
        if (!enabled) return
        if (resetRequested) {
            resetRequested = false
            meter.reset()
            lastIndex = -1
            lastPtsUs = Long.MIN_VALUE
        }
        // The renderer offers a buffer again until the sink has taken all of
        // it; the same buffer is not measured twice.
        if (bufferIndex == lastIndex && ptsUs == lastPtsUs) return
        lastIndex = bufferIndex
        lastPtsUs = ptsUs
        meter.process(buffer, (ptsUs - offsetUs) / 1_000_000.0)
    }

    private fun onWindow(timeSec: Double, db: Double) {
        synchronized(lock) {
            times.add(timeSec)
            levels.add(db)
            if (!flushScheduled) {
                flushScheduled = true
                main.postDelayed(flush, FLUSH_MS)
            }
        }
    }

    private fun clearPending() {
        synchronized(lock) {
            times.clear()
            levels.clear()
        }
    }

    private fun sendBatch() {
        val t: DoubleArray
        val db: DoubleArray
        synchronized(lock) {
            flushScheduled = false
            if (times.isEmpty()) return
            t = times.toDoubleArray()
            db = levels.toDoubleArray()
            times.clear()
            levels.clear()
        }
        deliver(mapOf("type" to "audioLevels", "t" to t, "db" to db))
    }
}
