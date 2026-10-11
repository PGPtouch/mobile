package com.jhubi1.apps.pgptouch

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * Plays the app's haptic patterns with the communication-request usage.
 *
 * The NFC service vibrates on every tag with the hardware-feedback usage and offers no way to opt
 * out, but the vibration service drops a new vibration while a higher-ranked one is running.
 * Communication request outranks hardware feedback, so a repeating pattern of ours that is running
 * when the tag arrives masks the system vibration.
 *
 * A pattern is played, in order of preference, as:
 *  1. an envelope effect (Android 16+, needs frequency control in the hardware): amplitude and
 *     frequency control points, linearly interpolated, so frequency can be part of the pattern;
 *  2. an amplitude waveform.
 * Vibrators without amplitude control do not vibrate at all.
 *
 * A pattern can repeat from some point on; what comes before is played once.
 */
class Haptics(context: Context) {
    private val vibrator: Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capabilities" -> result.success(capabilities())
            "play" -> result.success(play(call))
            "cancel" -> {
                cancel()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun cancel() {
        runCatching { vibrator?.cancel() }
    }

    private fun capabilities(): Map<String, Any?> {
        val vibrator = vibrator
        val result = mutableMapOf<String, Any?>(
            "sdk" to Build.VERSION.SDK_INT,
            "hasVibrator" to (vibrator?.hasVibrator() == true),
            "amplitudeControl" to (vibrator?.hasAmplitudeControl() == true),
            "envelope" to false,
        )
        if (vibrator != null && Build.VERSION.SDK_INT >= ENVELOPE_SDK) {
            runCatching {
                result["envelope"] = vibrator.areEnvelopeEffectsSupported()
                result["resonantFrequencyHz"] = vibrator.resonantFrequency.takeUnless { it.isNaN() }
                vibrator.frequencyProfile?.let {
                    result["minFrequencyHz"] = it.minFrequencyHz
                    result["maxFrequencyHz"] = it.maxFrequencyHz
                }
                vibrator.envelopeEffectInfo.let {
                    result["maxEnvelopeSize"] = it.maxSize
                    result["minControlPointMs"] = it.minControlPointDurationMillis
                    result["maxControlPointMs"] = it.maxControlPointDurationMillis
                    result["maxEnvelopeDurationMs"] = it.maxDurationMillis
                }
            }
        }
        return result
    }

    /**
     * Cancels what is running and plays the pattern. Returns how it was played: "envelope",
     * "waveform", or null when it could not be played (including a vibrator without amplitude
     * control).
     */
    private fun play(call: MethodCall): String? {
        val vibrator = vibrator ?: return null
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || !vibrator.hasVibrator()) return null

        // An ongoing repeating vibration wins against a new non-repeating one of the same usage.
        cancel()
        if (!vibrator.hasAmplitudeControl()) return null

        val timings = call.argument<List<Number>>("timings")?.map { it.toLong() }?.toLongArray()
        val amplitudes = call.argument<List<Number>>("amplitudes")?.map { it.toInt() }?.toIntArray()
        val repeatFrom = call.argument<Number>("repeatFrom")?.toInt()
        val envelope = call.argument<List<Map<String, Any?>>>("envelope")
        val envelopeRepeatFrom = call.argument<Number>("envelopeRepeatFrom")?.toInt()

        if (envelope != null) {
            val effect = runCatching { buildEnvelope(vibrator, envelope, envelopeRepeatFrom) }
                .onFailure { Log.w(TAG, "Building the envelope effect failed", it) }
                .getOrNull()
            if (effect != null && start(vibrator, effect)) return "envelope"
        }

        if (timings == null || amplitudes == null || timings.isEmpty() || amplitudes.size != timings.size) {
            return null
        }
        val effect = VibrationEffect.createWaveform(timings, amplitudes, repeatFrom ?: -1)
        return if (start(vibrator, effect)) "waveform" else null
    }

    private fun start(vibrator: Vibrator, effect: VibrationEffect): Boolean =
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                vibrator.vibrate(
                    effect,
                    VibrationAttributes.createForUsage(VibrationAttributes.USAGE_COMMUNICATION_REQUEST),
                )
            } else {
                // Maps to the communication-request usage.
                @Suppress("DEPRECATION")
                vibrator.vibrate(
                    effect,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION_SIGNALLING)
                        .build(),
                )
            }
        }.onFailure { Log.w(TAG, "vibrate failed", it) }.isSuccess

    /**
     * Control points are `{durationMs, amplitude 0..1, frequencyHz}`: the vibrator ramps linearly
     * to each one over its duration, starting from 0 amplitude. The points from [repeatFrom] on
     * repeat, the ones before are played once; both parts should end silent. Null if the device
     * cannot play envelope effects or the effect does not fit them.
     */
    private fun buildEnvelope(
        vibrator: Vibrator,
        points: List<Map<String, Any?>>,
        repeatFrom: Int?,
    ): VibrationEffect? {
        if (Build.VERSION.SDK_INT < ENVELOPE_SDK || !vibrator.areEnvelopeEffectsSupported()) return null
        val profile = vibrator.frequencyProfile ?: return null
        val info = vibrator.envelopeEffectInfo
        val limits = EnvelopeLimits(
            minFrequency = profile.minFrequencyHz,
            maxFrequency = profile.maxFrequencyHz,
            minDuration = max(info.minControlPointDurationMillis, 1L),
            maxDuration = max(info.maxControlPointDurationMillis, 1L),
            maxTotal = info.maxDurationMillis,
        )

        if (repeatFrom == null) return buildEnvelopeEffect(points, limits)
        val once = points.subList(0, repeatFrom.coerceIn(0, points.size))
        val repeating = points.subList(once.size, points.size)
        if (repeating.isEmpty()) return buildEnvelopeEffect(once, limits)
        val repeatingEffect = buildEnvelopeEffect(repeating, limits) ?: return null
        if (once.isEmpty()) return VibrationEffect.createRepeatingEffect(repeatingEffect)
        val onceEffect = buildEnvelopeEffect(once, limits) ?: return null
        return VibrationEffect.createRepeatingEffect(onceEffect, repeatingEffect)
    }

    private class EnvelopeLimits(
        val minFrequency: Float,
        val maxFrequency: Float,
        val minDuration: Long,
        val maxDuration: Long,
        val maxTotal: Long,
    )

    /**
     * Frequencies are clamped to the range the hardware supports and durations to what an
     * envelope control point can take; ramps longer than a control point may be are split into
     * several.
     */
    private fun buildEnvelopeEffect(points: List<Map<String, Any?>>, limits: EnvelopeLimits): VibrationEffect? {
        if (points.isEmpty()) return null
        fun clampFrequency(hz: Float) = min(max(hz, limits.minFrequency), limits.maxFrequency)

        val builder = VibrationEffect.WaveformEnvelopeBuilder()
        var amplitude = 0f
        var frequency = clampFrequency((points.first()["frequencyHz"] as Number).toFloat())
        builder.setInitialFrequencyHz(frequency)

        var total = 0L
        for (point in points) {
            val targetAmplitude = ((point["amplitude"] as Number).toFloat()).coerceIn(0f, 1f)
            val targetFrequency = clampFrequency((point["frequencyHz"] as Number).toFloat())
            val duration = max((point["durationMs"] as Number).toLong(), limits.minDuration)

            val steps = max(1, ceil(duration.toDouble() / limits.maxDuration).toInt())
            var spent = 0L
            for (step in 1..steps) {
                val stepEnd = duration * step / steps
                val stepDuration = max(stepEnd - spent, limits.minDuration)
                spent = stepEnd
                val fraction = step.toFloat() / steps
                builder.addControlPoint(
                    amplitude + (targetAmplitude - amplitude) * fraction,
                    frequency + (targetFrequency - frequency) * fraction,
                    stepDuration,
                )
                total += stepDuration
            }
            amplitude = targetAmplitude
            frequency = targetFrequency
        }

        if (limits.maxTotal > 0 && total > limits.maxTotal) return null
        return builder.build()
    }

    private companion object {
        const val TAG = "Haptics"

        // WaveformEnvelopeBuilder and the frequency profile APIs.
        const val ENVELOPE_SDK = 36
    }
}
