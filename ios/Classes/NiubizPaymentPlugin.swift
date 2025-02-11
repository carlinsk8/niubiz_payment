import Flutter
import UIKit
import VisaNetSDK

enum NiubizResultStatus {
    static let success: String = "SUCCESS"
    static let error: String = "ERROR"

    static let userCanceled: String = "USER_CANCELED"
}

public class NiubizPaymentPlugin: NSObject, FlutterPlugin, VisaNetDelegate {

  private var channel: FlutterMethodChannel? = nil
  private var channelResult: FlutterResult! = nil
  var merchantDefineData = [String: Any]()

  private var hostViewController: UIViewController!

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "niubiz_payment", binaryMessenger: registrar.messenger())
    let instance = NiubizPaymentPlugin()
    instance.hostViewController = UIApplication.shared.delegate!.window!!.rootViewController!
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initPayment":
      do {
            channelResult = result

            let args = call.arguments as! [String: Any]
            print("args: \(args)")
            // credentials
            let username = args["userName"] as! String
            let password = args["password"] as! String
            let merchantId = args["merchantId"] as! String

            // endPoint
            let isProduction = args["isProduction"] as! Bool
            

            // holder
            let name = args["name"] as! String
            let lastName = args["lastName"] as! String
            let email = args["email"] as! String

            // let amount = args["amount"] as! Double
            let purchaseNumber = createPurchaseNumber()

            // ui
            let logoTitle = args["titleBrand"] as? String
            //let logoAssetName = args["logoAssetName"] as? String

            //let daysSinceRegistration = String(args["daysSinceRegistration"] as! Int)
          let daysSinceRegistration = 0
            // print
            print("MDD77: \(daysSinceRegistration)")

            Config.TK.dataChannel = .mobile
            Config.merchantID = merchantId
            var endPoint = ""
            print("isProduction: \(isProduction)")
            if isProduction {
                Config.TK.type = .prod
                Config.TK.endPointProdURL = "https://apiprod.vnforapps.com"
                endPoint = "https://apiprod.vnforapps.com"
            } else {
                Config.TK.type = .dev
                Config.TK.endPointDevURL = "https://apitestenv.vnforapps.com"
                endPoint = "https://apitestenv.vnforapps.com"
            }

            //Config.amount = amount
            Config.TK.purchaseNumber = purchaseNumber

            Config.TK.firstName = name
            Config.TK.lastName = lastName
            Config.TK.email = email
            Config.TK.FirstNameField.defaultText = name
            Config.TK.LastNameField.defaultText = lastName

            var merchantDefineData = [String: Any]()
            merchantDefineData["MDD4"] = email // client email
            merchantDefineData["MDD21"] = "1" // frequent client (0 or 1)
            merchantDefineData["MDD32"] = email // code, dni, ruc, client id or email
            merchantDefineData["MDD75"] = "Registrado" // client registration type (Registrado)
            merchantDefineData["MDD77"] = daysSinceRegistration // day since client registration (0-365)
            Config.TK.Antifraud.merchantDefineData = merchantDefineData

            //let logoImage = UIImage.flutterImageWithName(name: logoAssetName!)
            //if logoImage != nil {
                //Config.TK.Header.type = .logo
               // Config.TK.Header.logoImage = logoImage
            //} else {
                // This doesn't work
                Config.TK.Header.type = .text
                Config.TK.Header.titleText = logoTitle
            //}

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
            print("error: \(error.localizedDescription)")
            resultData(code: NiubizResultStatus.error)
        }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  public func registrationDidEnd(serverError: Any?, responseData: Any?) {
        print("serverError: \(String(describing: serverError))")
        print("responseData: \(String(describing: responseData))")

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
                    print("response: \(response)")
                    resultData(message: "OK", data: response, raw: response)
                } else {
                    print("error: \(errorMessage)")
                    resultData(code: NiubizResultStatus.error, message: errorMessage, data: response, raw: response)
                }
            } else if let error = responseData as? NSError {
                resultData(code: NiubizResultStatus.error, message: error.localizedDescription)
            } else {
                handleUnknownResponse(responseData)
            }
        } catch {
            print("error: \(error.localizedDescription)")
            resultData(code: NiubizResultStatus.error)
        }
    }

    private func handleError(serverError: Any?) {
        if let error = serverError as? NSError {
            resultData(code: NiubizResultStatus.error, message: error.localizedDescription)
        } else {
            let errorMessage = String(describing: serverError)
            resultData(code: NiubizResultStatus.error, message: errorMessage)
        }
    }

    private func convertToJSONString(_ data: Any?) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: data!, options: [])
        return String(data: jsonData, encoding: .utf8) ?? ""
    }

    private func handleUnknownResponse(_ responseData: Any?) {
        let responseString = String(describing: responseData)
        if responseString.starts(with: "Optional(Canceled)") {
            print("user canceled")
            resultData(code: NiubizResultStatus.userCanceled)
        } else {
            resultData(code: NiubizResultStatus.error, message: responseString)
        }
    }

    private func resultData(code: String = NiubizResultStatus.success, message: String = "", data: String = "", raw: String = "") {
        let result = [
            "code": code,
            "message": message,
            "data": data,
            "raw": raw
        ] as [String: Any]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            channelResult(jsonString)
        } catch {
            print("error: \(error.localizedDescription)")
            channelResult(nil)
        }
    }

    private func createPurchaseNumber() -> String {
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        let timestampString = String(timestamp)
        return String(timestampString.prefix(12))
    }

    private func getSecurityToken(endPoint: String, username: String, password: String, success: @escaping (String) -> Void, failure: @escaping (String) -> Void) {
        let url = URL(string: "\(endPoint)/api.security/v1/security")!
        print("url: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let basicAuthString = ("\(username):\(password)".data(using: .utf8)!).base64EncodedString()
        print("basicAuthString: \(basicAuthString)")
        request.setValue(basicAuthString, forHTTPHeaderField: "Authorization")

        print("--> POST \(url.absoluteString)")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, _, error in
            if let error = error {
                print("get token error: \(error)")
                failure(error.localizedDescription)
            } else if let data = data {
                let token = String(decoding: data, as: UTF8.self)
                print("get token OK: \(token)")
                success(token)
            } else {
                print("get token error: unknown")
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
