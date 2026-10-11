package com.jhubi1.apps.pgptouch

import android.content.ComponentName
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Android's "Tap to share" (Quick Share) is driven by the NFC service itself: on every
 * ISO-DEP tag it discovers, it SELECTs the Gesture Exchange AID and, if Play Services'
 * `gestureexchange.service.HostApduService` answers, launches `GestureExchangeActivity`
 * on both phones. The Dart side (`NfcHceGuard` in `states2.dart`) stops that by claiming
 * the AID with this app's foreground-preferred emulation service and answering "not found".
 *
 * This activity contributes the two pieces that must not depend on the Flutter engine:
 *  - releasing that claim in [onPause]. A claim left registered while the app is in the
 *    background makes Android ask the user which app should handle the AID, which is worse
 *    than the popup it replaces;
 *  - the `tap_to_share` channel, which reports the system settings that wire the feature
 *    in, so the app can warn when the feature is active and the guard could not win.
 *
 * The NFC-A-only discovery restriction applied here is kept from before, but it is not what
 * blocks Tap to share: popups were observed with it active.
 */
class MainActivity : FlutterActivity() {
    private val nfcAdapter: NfcAdapter? by lazy { NfcAdapter.getDefaultAdapter(this) }
    private val haptics by lazy { Haptics(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HAPTICS_CHANNEL)
            .setMethodCallHandler { call, result -> haptics.handle(call, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TAP_TO_SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(readTapToShareSettings())
                    "antennaLocations" -> result.success(readAntennaLocations())
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            runCatching {
                nfcAdapter?.setDiscoveryTechnology(
                    this,
                    NfcAdapter.FLAG_READER_NFC_A,
                    NfcAdapter.FLAG_LISTEN_NFC_PASSIVE_A,
                )
            }
        }
    }

    override fun onPause() {
        releaseEmulationClaim()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            runCatching { nfcAdapter?.resetDiscoveryTechnology(this) }
        }
        super.onPause()
    }

    // Not in onPause: delivering a tag to this activity pauses and resumes it, and cancelling
    // the running vibration there lets the NFC service's own vibration through.
    override fun onStop() {
        haptics.cancel()
        super.onStop()
    }

    /**
     * Drops the foreground preference and every AID this app's emulation service holds.
     * Dart re-claims them on resume. Only the AIDs go: the service stays as the plugin left it.
     */
    private fun releaseEmulationClaim() {
        runCatching {
            val adapter = nfcAdapter ?: return
            val emulation = CardEmulation.getInstance(adapter)
            emulation.unsetPreferredService(this)
            emulation.removeAidsForService(
                ComponentName(this, APDU_SERVICE_CLASS),
                CardEmulation.CATEGORY_OTHER,
            )
        }
    }

    /**
     * NFC antenna positions as fractions (0.0-1.0) of the device size, measured from the
     * top-left corner with the screen facing the viewer. Null when unknown (needs Android 14+) or on foldables.
     */
    private fun readAntennaLocations(): List<Map<String, Double>>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return null
        val info = runCatching { nfcAdapter?.nfcAntennaInfo }.getOrNull() ?: return null
        if (info.isDeviceFoldable) return null
        val width = info.deviceWidth
        val height = info.deviceHeight
        if (width <= 0 || height <= 0) return null
        return info.availableNfcAntennas.map {
            mapOf(
                "x" to it.locationX.toDouble() / width,
                "y" to it.locationY.toDouble() / height,
            )
        }
    }

    /** The system settings through which Android wires Tap to share into the NFC service. */
    private fun readTapToShareSettings(): Map<String, Any?> {
        fun secure(key: String): String? =
            runCatching { Settings.Secure.getString(contentResolver, key) }
                .getOrNull()
                ?.takeIf { it.isNotBlank() && it != "null" }

        return mapOf(
            "sdk" to Build.VERSION.SDK_INT,
            "gestureExchangeComponent" to secure("nfc.gesture_exchange_component"),
            "tapEventServiceComponent" to secure("tap_event_service_component"),
            "secondaryAid" to secure("nfc.gesture_exchange_secondary_aid"),
        )
    }

    private companion object {
        const val TAP_TO_SHARE_CHANNEL = "mobile/tap_to_share"
        const val HAPTICS_CHANNEL = "mobile/haptics"

        // nfc_util's emulation service. Referenced by name because it belongs to the plugin.
        const val APDU_SERVICE_CLASS = "com.onderada.nfc_util.NfcUtilApduService"
    }
}
