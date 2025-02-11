import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:niubiz_payment/niubiz_payment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _response = '';
  final _niubizPaymentPlugin = NiubizPayment();

  Future<void> initNiubizPayment() async {
    final NiubizConfigModel config = NiubizConfigModel(
      userName: "integraciones@niubiz.com.pe", // userName
      merchantId: "456879852", // merchantId
      password: "_7z3@8fF", // password
      isProduction: false, // true for production
      titleBrand: "Niubiz",
      name: "test1",
      lastName: "test2",
      email: "test@gmail.com",
    );
    String response;
    try {
      response = await _niubizPaymentPlugin.initPayment(config) ?? '{"error":"Failed to init niubiz payment"}';
    } on PlatformException {
      response = '{"error":"Failed to init niubiz payment."}';
    }
    if (!mounted) return;

    setState(() {
      _response = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: TextButton(
                onPressed: initNiubizPayment,
                child: const Text('initPayment'),
              ),
            ),
            if (_response.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: JsonView.string(
                  _response,
                  theme: const JsonViewTheme(
                    backgroundColor: Colors.black12,
                    keyStyle: TextStyle(color: Colors.blue),
                    stringStyle: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _response));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: const Text('Copy to clipboard'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
