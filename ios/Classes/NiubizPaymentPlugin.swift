import Flutter
import UIKit
import VisaNetSDK

enum NiubizResultStatus {
    static let success = "SUCCESS"
    static let error = "ERROR"
    static let userCanceled = "USER_CANCELED"
}

public class NiubizPaymentPlugin: NSObject, FlutterPlugin, VisaNetDelegate {

    private var channel: FlutterMethodChannel?
    private var channelResult: FlutterResult?
    private var hostViewController: UIViewController!
    private var merchantDefineData = [String: Any]()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "niubiz_payment", binaryMessenger: registrar.messenger())
        let instance = NiubizPaymentPlugin()
        instance.hostViewController = UIApplication.shared.delegate!.window!!.rootViewController!
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initPayment":
            channelResult = result
            guard let args = call.arguments as? [String: Any] else {
                resultData(code: NiubizResultStatus.error, message: "Invalid arguments")
                return
            }
            initPayment(args: args)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initPayment(args: [String: Any]) {
        do {
            let username: String = try getArgument(args, key: "userName")
            let password: String = try getArgument(args, key: "password")
            let merchantId: String = try getArgument(args, key: "merchantId")
            let isProduction: Bool = try getArgument(args, key: "isProduction")
            let name: String = try getArgument(args, key: "name")
            let lastName: String = try getArgument(args, key: "lastName")
            let email: String = try getArgument(args, key: "email")

            let purchaseNumber = createPurchaseNumber()
            let logoTitle = args["titleBrand"] as? String
            let daysSinceRegistration = 0

            Config.TK.dataChannel = .mobile
            Config.merchantID = merchantId
            Config.TK.type = isProduction ? .prod : .dev
            Config.TK.endPointProdURL = "https://apiprod.vnforapps.com"
            Config.TK.endPointDevURL = "https://apitestenv.vnforapps.com"
            Config.TK.purchaseNumber = purchaseNumber
            Config.TK.firstName = name
            Config.TK.lastName = lastName
            Config.TK.email = email
            Config.TK.FirstNameField.defaultText = name
            Config.TK.LastNameField.defaultText = lastName

            merchantDefineData = [
                "MDD4": email,
                "MDD21": "1",
                "MDD32": email,
                "MDD75": "Registrado",
                "MDD77": daysSinceRegistration
            ]
            Config.TK.Antifraud.merchantDefineData = merchantDefineData

            Config.TK.Header.type = .text
            Config.TK.Header.titleText = logoTitle

            let endPoint = isProduction ? "https://apiprod.vnforapps.com" : "https://apitestenv.vnforapps.com"
            getSecurityToken(endPoint: endPoint, username: username, password: password) { token in
                DispatchQueue.main.async {
                    Config.securityToken = token
                    VisaNet.shared.delegate = self
                    _ = VisaNet.shared.presentVisaPaymentForm(viewController: self.hostViewController)
                }
            } failure: { error in
                self.resultData(code: NiubizResultStatus.error, message: error)
            }
        } catch {
            resultData(code: NiubizResultStatus.error, message: error.localizedDescription)
        }
    }

    private func getArgument<T>(_ args: [String: Any], key: String) throws -> T {
        guard let value = args[key] as? T else {
            throw NSError(domain: "Invalid argument", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid argument: \(key)"])
        }
        return value
    }

    public func registrationDidEnd(serverError: Any?, responseData: Any?) {
        guard serverError == nil else {
            handleError(serverError: serverError)
            return
        }

        do {
            if let jsonResult = responseData as? [String: Any] {
                let response = try convertToJSONString(responseData)
                let errorCode = jsonResult["errorCode"] as? Int ?? 0
                let errorMessage = jsonResult["errorMessage"] as? String ?? ""

                if errorCode == 0 && errorMessage == "OK" {
                    resultData(message: "OK", data: response, raw: response)
                } else {
                    resultData(code: NiubizResultStatus.error, message: errorMessage, data: response, raw: response)
                }
            } else if let error = responseData as? NSError {
                resultData(code: NiubizResultStatus.error, message: error.localizedDescription)
            } else {
                handleUnknownResponse(responseData)
            }
        } catch {
            resultData(code: NiubizResultStatus.error, message: error.localizedDescription)
        }
    }

    private func handleError(serverError: Any?) {
        if let error = serverError as? NSError {
            resultData(code: NiubizResultStatus.error, message: error.localizedDescription)
        } else {
            resultData(code: NiubizResultStatus.error, message: String(describing: serverError))
        }
    }

    private func convertToJSONString(_ data: Any?) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: data!, options: [])
        return String(data: jsonData, encoding: .utf8) ?? ""
    }

    private func handleUnknownResponse(_ responseData: Any?) {
        let responseString = String(describing: responseData)
        if responseString.starts(with: "Optional(Canceled)") {
            resultData(code: NiubizResultStatus.userCanceled)
        } else {
            resultData(code: NiubizResultStatus.error, message: responseString)
        }
    }

    private func resultData(code: String = NiubizResultStatus.success, message: String = "", data: String = "", raw: String = "") {
        let result: [String: Any] = [
            "code": code,
            "message": message,
            "data": data,
            "raw": raw
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            channelResult?(jsonString)
        } catch {
            channelResult?(nil)
        }
    }

    private func createPurchaseNumber() -> String {
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        return String(Int(timestamp))
    }

    private func getSecurityToken(endPoint: String, username: String, password: String, success: @escaping (String) -> Void, failure: @escaping (String) -> Void) {
        guard let url = URL(string: "\(endPoint)/api.security/v1/security") else {
            failure("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let basicAuthString = ("\(username):\(password)".data(using: .utf8)!).base64EncodedString()
        request.setValue("Basic \(basicAuthString)", forHTTPHeaderField: "Authorization")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, _, error in
            if let error = error {
                failure(error.localizedDescription)
            } else if let data = data {
                let token = String(decoding: data, as: UTF8.self)
                success(token)
            } else {
                failure("Unknown error")
            }
        }

        task.resume()
    }
}

extension UIImage {
    static func flutterImageWithName(name: String) -> UIImage? {
        let key = FlutterDartProject.lookupKey(forAsset: name)
        return UIImage(named: key, in: Bundle.main, with: nil)
    }
}
