package com.pginfo.manage

import android.app.Activity
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.ApiException
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var phoneNumberChannel: MethodChannel? = null
    private var phoneNumberResult: MethodChannel.Result? = null

    private val phoneNumberPicker =
        registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { result ->
            val data = result.data
            val number = if (result.resultCode == Activity.RESULT_OK && data != null) {
                try {
                    Identity.getSignInClient(this).getPhoneNumberFromIntent(data)
                } catch (_: ApiException) {
                    null
                }
            } else {
                null
            }
            finishPhoneNumberRequest(number)
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        phoneNumberChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.pginfo.manage/phone_number_hint",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "requestPhoneNumber") {
                    requestPhoneNumber(result)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestPhoneNumber(result: MethodChannel.Result) {
        if (phoneNumberResult != null) {
            result.success(null)
            return
        }
        phoneNumberResult = result
        val request = GetPhoneNumberHintIntentRequest.builder().build()
        Identity.getSignInClient(this).getPhoneNumberHintIntent(request)
            .addOnSuccessListener { pendingIntent ->
                if (phoneNumberResult !== result) return@addOnSuccessListener
                try {
                    phoneNumberPicker.launch(IntentSenderRequest.Builder(pendingIntent).build())
                } catch (_: IllegalStateException) {
                    finishPhoneNumberRequest(null)
                }
            }
            .addOnFailureListener {
                if (phoneNumberResult === result) finishPhoneNumberRequest(null)
            }
    }

    private fun finishPhoneNumberRequest(number: String?) {
        val result = phoneNumberResult
        phoneNumberResult = null
        result?.success(number)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        finishPhoneNumberRequest(null)
        phoneNumberChannel?.setMethodCallHandler(null)
        phoneNumberChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
