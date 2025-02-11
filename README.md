# niubiz_payment

A Flutter plugin to integrate the official Niubiz SDKs on Android and iOS, allowing payments directly in Flutter applications.

📌 Official documentation:
- [Android SDK](https://desarrolladores.niubiz.com.pe/docs/tokenizaci%C3%B3n-android-copy)
- [iOS SDK](https://desarrolladores.niubiz.com.pe/docs/tokenizaci%C3%B3n-ios-copy)

---

## Platform Support

This package supports the following platforms:

✅ **Android**  
✅ **iOS**  
❌ **Windows** (Not Supported)  
❌ **macOS** (Not Supported)  
❌ **Linux** (Not Supported)  
❌ **Web** (Not Supported)  

This plugin is designed to work exclusively on **Android** and **iOS**.  
For more details, refer to the official documentation.  

📌 Requires a minimum of iOS 13:
```text
platform :ios, '13.0'
```

## 🛠 Usage in Flutter

### 1. Add the dependency in `pubspec.yaml`
Add the library in `pubspec.yaml`:

```yaml
dependencies:
  niubiz_payment:
   path: ../niubiz_payment
```

### 2. Import the library and use the plugin
In the Flutter code, import the package and call the payment initiation method:

```dart
import 'package:niubiz_payment/niubiz_payment.dart';

Future<void> initPayment() async {
    final _niubizPaymentPlugin = NiubizPayment();
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
   try {
    response = await _niubizPaymentPlugin.startPayment(config);
    // Send the response to the service
    print(response);
   } on PlatformException {
    response = 'Failed to get platform version.';
    setState(() {});
   }
}
```

---

## ✅ Example of a successful response

```json
{
	"card": {
		"brand": "visa",
		"cardNumber": "414532******2334",
		"expirationMonth": "10",
		"expirationYear": "27",
		"firstName": "test1",
		"lastName": "test2"
	},
	"errorCode": 0,
	"errorMessage": "OK",
	"header": {
		"ecoreTransactionDate": 1739223793491,
		"ecoreTransactionUUID": "2342dff7-4480-4521-b0ea-f471dab9d423",
		"millis": 73
	},
	"order": {
		"actionCode": "000",
		"actionDescription": "Aprobado y completado con exito",
		"status": "Verified"
	},
	"token": {
		"expireOn": "271031235959",
		"ownerId": "test@gmail.com",
		"tokenId": "7000010353243623"
	}
}
```

---

📌 **Notes:**
- Verify that the configuration values are correct according to the environment (sandbox, test, production).
- Properly handle platform errors to improve user experience.

🎯 Ready! Now you can integrate Niubiz payments into your Flutter app. 🚀

