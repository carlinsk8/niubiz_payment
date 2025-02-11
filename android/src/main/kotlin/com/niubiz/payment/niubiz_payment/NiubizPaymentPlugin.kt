package com.niubiz.payment.niubiz_payment

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

import android.util.Log
import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import io.flutter.embedding.android.FlutterActivity

import java.net.HttpURLConnection
import java.net.URL
import android.util.Base64
import java.nio.charset.StandardCharsets

import lib.visanet.com.pe.visanetlib.VisaNet
import lib.visanet.com.pe.visanetlib.data.custom.Channel
import lib.visanet.com.pe.visanetlib.presentation.custom.VisaNetViewAuthorizationCustom

class NiubizPaymentPlugin: FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
PluginRegistry.ActivityResultListener {
  private var channel: MethodChannel? = null
  private var channelResult: MethodChannel.Result? = null
  private var activity: FlutterActivity? = null
  private var flutterBinding: FlutterPlugin.FlutterPluginBinding? = null
  private var activityBinding: ActivityPluginBinding? = null

  companion object {
    const val CHANNEL_NAME = "niubiz_payment"
    const val EXPECTED_REQUEST_CODE = 1001

    @JvmStatic
    fun registerWith(registrar: PluginRegistry.Registrar) {
      val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
      channel.setMethodCallHandler(NiubizPaymentPlugin())
    }
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    flutterBinding = flutterPluginBinding
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    channelResult = result
    if (call.method == "initPayment") {
      val args = call.arguments as? Map<String, Any> ?: run {
        result.error("INVALID_ARGUMENTS", "Invalid arguments received from Dart", null)
        return
      }
      val titleBrand = args["titleBrand"] as? String ?: "Niubiz"
      val merchantId = args["merchantId"] as? String ?: "456879852"
      val userName = args["userName"] as? String ?: "integraciones@niubiz.com.pe"
      val password = args["password"] as? String ?: "_7z3@8fF"
      val name = args["name"] as? String ?: "test1"
      val lastName = args["lastName"] as? String ?: "test2"
      val email = args["email"] as? String ?: "test@gmail.com"
      val isProduction = args["isProduction"] as? Boolean ?: false

      val custom = VisaNetViewAuthorizationCustom().apply {
        setLogoTextMerchant(true)
        setLogoTextMerchantText(titleBrand)
      }

      CoroutineScope(Dispatchers.Main).launch {
        try {
          val token = obtenerTokenSesion(merchantId, userName, password, isProduction)
          if (token != null) {
            val parameters = createParameters(call, token, isProduction, merchantId, name, lastName, email)
            try {
              VisaNet.tokenization(activity, parameters, custom)
            } catch (e: Exception) {
              result.error("UNAVAILABLE", "Error during tokenization", e.message)
            }
          } else {
            result.error("UNAVAILABLE", "Error obtaining session token", null)
          }
        } catch (e: Exception) {
          result.error("UNAVAILABLE", "Error obtaining session token", e.message)
        }
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    flutterBinding = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    channel = MethodChannel(flutterBinding!!.binaryMessenger, CHANNEL_NAME)
    channel?.setMethodCallHandler(this)

    activityBinding = binding
    activityBinding?.addActivityResultListener(this)
    activity = binding.activity as FlutterActivity
  }

  override fun onDetachedFromActivity() {
    channel?.setMethodCallHandler(null)
    channel = null
    channelResult = null

    activityBinding?.removeActivityResultListener(this)
    activityBinding = null
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  private suspend fun obtenerTokenSesion(
    merchantId: String,
    userName: String,
    password: String,
    isProduction: Boolean
  ): String? {
    val apiUrl = if (!isProduction) {
      "https://apitestenv.vnforapps.com"
    } else {
      "https://apiprod.vnforapps.com"
    }

    val authHeader = "Basic " + Base64.encodeToString(
      "$userName:$password".toByteArray(StandardCharsets.UTF_8),
      Base64.NO_WRAP
    )

    return withContext(Dispatchers.IO) {
      val url = URL("$apiUrl/api.security/v1/security")
      val connection = url.openConnection() as HttpURLConnection
      connection.requestMethod = "POST"
      connection.setRequestProperty("Authorization", authHeader)
      try {
        if (connection.responseCode == HttpURLConnection.HTTP_CREATED) {
          connection.inputStream.bufferedReader().use { it.readText() }
        } else {
          null
        }
      } finally {
        connection.disconnect()
      }
    }
  }

  private fun createParameters(
    call: MethodCall,
    token: String,
    isProduction: Boolean,
    merchantId: String,
    name: String,
    lastName: String,
    email: String
  ): Map<String, Any?> {
    val endPoint = if (!isProduction) {
      "https://apitestenv.vnforapps.com"
    } else {
      "https://apiprod.vnforapps.com"
    }
    val endPointExt = endPoint + (if (endPoint.endsWith("/")) "" else "/")
    val parameters = HashMap<String, Any?>().apply {
      put(VisaNet.VISANET_CHANNEL, Channel.MOBILE)
      put(VisaNet.VISANET_MERCHANT, merchantId)
      put(VisaNet.VISANET_ENDPOINT_URL, endPointExt)
      put(VisaNet.VISANET_PURCHASE_NUMBER, System.currentTimeMillis().toString().substring(0, 12))
      put(VisaNet.VISANET_TOKENIZATION_NAME, name)
      put(VisaNet.VISANET_TOKENIZATION_LASTNAME, lastName)
      put(VisaNet.VISANET_TOKENIZATION_EMAIL, email)
      put(VisaNet.VISANET_SECURITY_TOKEN, token)
      put(VisaNet.VISANET_TOKENIZATION_AMOUNT, 1.0)
    }

    val daysSinceRegistration = call.argument<Int>("daysSinceRegistration") ?: 0
    val mdds = HashMap<String, String>().apply {
      put("MDD4", email)
      put("MDD21", "1")
      put("MDD32", email)
      put("MDD75", "Registrado")
      put("MDD77", daysSinceRegistration.toString())
    }
    parameters[VisaNet.VISANET_MDD] = mdds
    return parameters
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == VisaNet.VISANET_TOKENIZATION) {
      val responseString = data?.extras?.getString(if (resultCode == Activity.RESULT_OK) "keySuccess" else "keyError")
      channelResult?.success(responseString ?: "{\"error\":\"cancel\"}")
      return true
    }
    return false
  }
}
