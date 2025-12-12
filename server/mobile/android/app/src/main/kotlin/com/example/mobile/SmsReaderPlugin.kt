package com.example.mobile

import android.Manifest
import android.content.BroadcastReceiver
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract
import android.provider.Telephony
import android.telephony.SmsMessage
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SmsReaderPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private var smsReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "sms_reader/methods")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "sms_reader/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInboxSms" -> {
                val limit = call.argument<Int>("limit") ?: 100
                val startDate = call.argument<Long>("startDate")
                getInboxSms(limit, startDate, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun getInboxSms(limit: Int, startDate: Long?, result: MethodChannel.Result) {
        try {
            val messages = mutableListOf<Map<String, Any?>>()
            val contentResolver: ContentResolver = context.contentResolver
            val uri = Uri.parse("content://sms/inbox")
            
            var selection: String? = null
            var selectionArgs: Array<String>? = null
            
            if (startDate != null) {
                selection = "date >= ?"
                selectionArgs = arrayOf(startDate.toString())
            }

            val cursor = contentResolver.query(
                uri,
                arrayOf("_id", "address", "body", "date"),
                selection,
                selectionArgs,
                "date DESC LIMIT $limit"
            )

            cursor?.use {
                val addressIndex = it.getColumnIndex("address")
                val bodyIndex = it.getColumnIndex("body")
                val dateIndex = it.getColumnIndex("date")

                while (it.moveToNext()) {
                    val rawAddress = if (addressIndex >= 0) it.getString(addressIndex) else ""
                    val contactName = getContactNameIfPossible(rawAddress)
                    val body = if (bodyIndex >= 0) it.getString(bodyIndex) else ""
                    val date = if (dateIndex >= 0) it.getLong(dateIndex) else 0L

                    messages.add(
                        mapOf(
                            // Keep the raw numeric address, and also add a resolved sender name (contact)
                            "address" to rawAddress,
                            "sender" to contactName,
                            "body" to body,
                            "date" to date
                        )
                    )
                }
            }

            result.success(messages)
        } catch (e: Exception) {
            result.error("SMS_READ_ERROR", e.message, null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                    val bundle = intent.extras
                    if (bundle != null) {
                        val pdus = bundle.get("pdus") as Array<*>
                                        for (pdu in pdus) {
                                            val message = SmsMessage.createFromPdu(pdu as ByteArray)
                                            val rawAddress = message.originatingAddress
                                            val contactName = getContactNameIfPossible(rawAddress)
                                            val smsData = mapOf(
                                                // Provide both raw numeric address and optionally-resolved contact name
                                                "address" to rawAddress,
                                                "sender" to contactName,
                                                "body" to message.messageBody,
                                                "date" to message.timestampMillis
                                            )
                            eventSink?.success(smsData)
                        }
                    }
                }
            }
        }

        val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        context.registerReceiver(smsReceiver, filter)
    }

    override fun onCancel(arguments: Any?) {
        smsReceiver?.let {
            context.unregisterReceiver(it)
        }
        smsReceiver = null
        eventSink = null
    }

    companion object {
        fun registerWith(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
            flutterEngine.plugins.add(SmsReaderPlugin())
        }
    }

    // Try to resolve a phone number into a contact display name, if the app has permission.
    private fun getContactNameIfPossible(rawAddress: String?): String {
        if (rawAddress.isNullOrEmpty()) return ""

        // If it's already an alpha sender (like BANK_SHORT_CODES), return as is
        if (!rawAddress.matches(Regex("^[\\d+]+$"))) {
            return rawAddress
        }

        try {
            // Check read contacts permission
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
                return rawAddress
            }

            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(rawAddress))
            var name: String? = null
            context.contentResolver.query(uri, arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                    if (nameIndex >= 0) {
                        name = cursor.getString(nameIndex)
                    }
                }
            }

            return name ?: rawAddress
        } catch (e: Exception) {
            return rawAddress
        }
    }
}
