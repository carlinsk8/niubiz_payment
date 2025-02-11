
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:niubiz_payment/niubiz_config_model.dart';
export 'niubiz_config_model.dart';

/// Handles Niubiz payment integration using Flutter's MethodChannel.
class NiubizPayment {
  static const MethodChannel _channel = MethodChannel('niubiz_payment');

  /// Starts a payment process with the given [config].
  /// Returns a response as a [String] or an error message if the process fails.
  Future<String?> initPayment(NiubizConfigModel config) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError("{\"error\" : \"Niubiz is only supported on Android and iOS}\"");
    }
    try {
      final response = await _channel.invokeMethod('initPayment', config.toMap());
      return "$response";
    } on Exception catch (e) {
      return '{"error":"Failed to init niubiz payment: $e"}';

    }
  }
}
