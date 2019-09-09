import Flutter
import UIKit
import StoneSDK

public class SwiftFlutterStonePlugin: NSObject, FlutterPlugin {

    private let registrar: FlutterPluginRegistrar
    private var currentDevice: STNPinpad?
    
    init(_ registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    /**
     Handle method calls here
     */
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method) {
        case "startStoneSdk":
            startPlugin(result, call.arguments)
            break
        case "writeToDisplay":
            writeToDisplay(result, call.arguments)
            break
        case "connect":
            connectToDevice(result)
            break
        case "makeTransaction":
            makeTransaction(result, call.arguments)
            break
        default:
            print("Unknown method: \(call.method)")
            break
        }
    }
    
    private func startPlugin(_ result: @escaping FlutterResult, _ arguments: Any?) {
        let argumentsJsonString = arguments as! String
        let data = argumentsJsonString.data(using: String.Encoding.utf8)!
        do {
            let obj = try JSONDecoder().decode(InitArguments.self, from: data)
            STNStoneCodeActivationProvider.activateStoneCode(obj.stoneCode) { (activated, error) in
                if(activated) {
                    result(true)
                } else {
                    if(error != nil && (error! as NSError).code == 202) {
                        result(true)
                    } else {
                        result(false)
                    }
                }
            }
            STNConfig.environment = obj.mode == "SANDBOX" ? STNEnvironmentSandbox : STNEnvironmentProduction
            
        } catch let jsonError {
            print(jsonError)
            result(false)
        }
    }
    
    private func connectToDevice(_ result: @escaping FlutterResult) {
        let devices = STNPinPadConnectionProvider().listConnectedPinpads()
        let device = devices.first
        if(device != nil) {
            STNPinPadConnectionProvider().select(device!) { (connected, error) in
                do {
                    let dartErrorCode: Int?
                    let selectedDevice: BluetoothDevice?
                    if(connected) {
                        dartErrorCode = nil
                        self.currentDevice = device
                        selectedDevice = BluetoothDevice(name: device!.name)
                    } else {
                        dartErrorCode = self.mapErrorCodeToDartErrorCode(errorCode: (error as NSError?)?.code)
                        self.currentDevice = nil
                        selectedDevice = nil
                    }
                    let event = IOSConnectionEvent(errorCode: dartErrorCode, device: selectedDevice)
                    let data = try JSONEncoder().encode(event)
                    let jsonString = String(data: data, encoding: .utf8)
                    result(jsonString)
                } catch let jsonError {
                    print(jsonError)
                    result(nil)
                }
            }
        } else {
            do {
                let event = IOSConnectionEvent(errorCode: SwiftFlutterStonePlugin.PINPAD_CONNECTION_NOT_FOUND, device: nil)
                let data = try JSONEncoder().encode(event)
                let jsonString = String(data: data, encoding: .utf8)
                result(jsonString)
            } catch let jsonError {
                print(jsonError)
                result(nil)
            }
        }
    }
    
    private func writeToDisplay(_ result: @escaping FlutterResult, _ arguments: Any?) {
        let message = arguments as! String
        STNDisplayProvider.displayMessage(message) { (wrote, error) in
            result(wrote)
        }
    }
    
    private func makeTransaction(_ result: @escaping FlutterResult, _ transactionData: Any?) {
        let transactionJson = transactionData as! String
        let data = transactionJson.data(using: String.Encoding.utf8)!
        do {
            let obj = try JSONDecoder().decode(Transaction.self, from: data)
            let transactionModel = buildTransactionModelFromTransaction(obj)
            STNTransactionProvider.sendTransaction(transactionModel) { (transactionSuccess, error) in
                do {
                    if(transactionSuccess) {
                        let event = TransactionEvent(
                            errorCode: nil,
                            transactionDate: transactionModel.dateString,
                            cardBrand: transactionModel.cardBrandString,
                            cardNumber: transactionModel.cardHolderNumber,
                            cardHolderName: transactionModel.cardHolderName,
                            transactionNumber: transactionModel.initiatorTransactionKey,
                            typeofTransaction: transactionModel.type == STNTransactionTypeSimplifiedDebit ? 1 : 2,
                            authorizationCode: transactionModel.authorisationCode,
                            instalmentCount: obj.instalmentCount,
                            transactionStatus: transactionModel.status == STNTransactionStatusApproved ? 1 : 2
                        )
                        let data = try JSONEncoder().encode(event)
                        let jsonString = String(data: data, encoding: .utf8)
                        result(jsonString)
                        
                    } else {
                        let errorCode = self.mapErrorCodeToDartErrorCode(errorCode: (error as NSError?)?.code)
                        let event = TransactionEvent.init(
                            errorCode: errorCode,
                            transactionDate: nil,
                            cardBrand: nil,
                            cardNumber: nil,
                            cardHolderName: nil,
                            transactionNumber: nil,
                            typeofTransaction: nil,
                            authorizationCode: nil,
                            instalmentCount: nil,
                            transactionStatus: nil
                        )
                        
                        let data = try JSONEncoder().encode(event)
                        let jsonString = String(data: data, encoding: String.Encoding.utf8)
                        result(jsonString)
                    }
                } catch let parsingError {
                    print(parsingError)
                    result(nil)
                }
            }
        } catch let jsonError {
            print(jsonError)
            result(nil)
        }
    }
    private func buildTransactionModelFromTransaction(_ obj: Transaction) -> STNTransactionModel {
        let transaction = STNTransactionModel()
        transaction.amount = NSNumber(value: Int(obj.amount)!)
        transaction.type = obj.typeOfTransaction == 1 ? STNTransactionTypeSimplifiedDebit : STNTransactionTypeSimplifiedCredit
        transaction.shortName = obj.shortName
        transaction.instalmentType = obj.typeOfTransaction == 1 ? STNInstalmentTypeNone : STNInstalmentTypeIssuer
        transaction.subMerchantCategoryCode = obj.subMerchantCategoryCode
        transaction.subMerchantPostalAddress = obj.subMerchantPostalAddress
        transaction.subMerchantTaxIdentificationNumber = obj.subMerchantTaxIdentificationNumber
        transaction.subMerchantRegisteredIdentifier = obj.subMerchantRegistedIdentifier
        transaction.merchant = STNMerchantListProvider.listMerchants()?.first as? STNMerchantModel
        
        if(obj.typeOfTransaction == 1) {
            transaction.instalmentAmount = STNTransactionInstalmentAmountOne
        } else {
            switch(obj.instalmentCount) {
            case 1:
                transaction.instalmentAmount = STNTransactionInstalmentAmountOne
                break
            case 2:
                transaction.instalmentAmount = STNTransactionInstalmentAmountTwo
                break
            case 3:
                transaction.instalmentAmount = STNTransactionInstalmentAmountThree
                break
            case 4:
                transaction.instalmentAmount = STNTransactionInstalmentAmountFour
                break
            case 5:
                transaction.instalmentAmount = STNTransactionInstalmentAmountFive
                break
            case 6:
                transaction.instalmentAmount = STNTransactionInstalmentAmountSix
                break
            case 7:
                transaction.instalmentAmount = STNTransactionInstalmentAmountSeven
                break
            case 8:
                transaction.instalmentAmount = STNTransactionInstalmentAmountEight
                break
            case 9:
                transaction.instalmentAmount = STNTransactionInstalmentAmountNine
                break
            case 10:
                transaction.instalmentAmount = STNTransactionInstalmentAmountTen
                break
            case 11:
                transaction.instalmentAmount = STNTransactionInstalmentAmountEleven
                break
            default:
                transaction.instalmentAmount = STNTransactionInstalmentAmountTwelve
                break
            }
        }
        
        return transaction
    }
    
    /**
     Plugin Entrypoint
     Start delegates here
     */
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_stone", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterStonePlugin(registrar)
        
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    struct InitArguments: Codable {
        let mode: String
        let stoneCode: String
    }
    
    struct IOSConnectionEvent: Codable {
        let errorCode: Int?
        let device: BluetoothDevice?
    }
    
    struct BluetoothDevice: Codable {
        let name: String
    }
    
    struct Transaction: Codable {
        let amount: String
        let instalmentCount: Int
        let typeOfTransaction: Int
        let shortName: String
        let initiatorTransactionKey: String?
        let subMerchantCategoryCode: String
        let subMerchantPostalAddress: String
        let subMerchantRegistedIdentifier: String
        let subMerchantTaxIdentificationNumber: String
    }
    
    struct TransactionEvent: Codable {
        let errorCode: Int?
        let transactionDate: String?
        let cardBrand: String?
        let cardNumber: String?
        let cardHolderName: String?
        let transactionNumber: String?
        let typeofTransaction: Int?
        let authorizationCode: String?
        let instalmentCount: Int?
        let transactionStatus: Int?
    }
    
    private func mapErrorCodeToDartErrorCode(errorCode: Int?) -> Int? {
        if(errorCode == nil) {
            return nil
        }
        
        let code: Int        
        switch(errorCode) {
        case 101:
            code = SwiftFlutterStonePlugin.GENERIC_ERROR
            break
        case 201, 202, 209:
            code = SwiftFlutterStonePlugin.PROVIDER_NOT_CONFIGURED
            break
        case 203:
            code = SwiftFlutterStonePlugin.TRANSACTION_AMOUNT_INVALID
            break
        case 204:
            code = SwiftFlutterStonePlugin.TRANSACTION_ABORTED
            break
        case 205, 220, 221:
            code = SwiftFlutterStonePlugin.TRANSACTION_INVALID
            break
        case 1, 206:
            code = SwiftFlutterStonePlugin.TRANSACTION_FAILED
            break
        case 207:
            code = SwiftFlutterStonePlugin.TRANSACTION_EXPIRED
            break
        case 211:
            code = SwiftFlutterStonePlugin.TRANSACTION_DECLINED
            break
        case 214, 215:
            code = SwiftFlutterStonePlugin.TRANSACTION_CANCELLED_BY_USER
            break
        case 303, 306:
            code = SwiftFlutterStonePlugin.PINPAD_CONNECTION_NOT_FOUND
            break
        case 304, 305, 307:
            code = SwiftFlutterStonePlugin.PINPAD_NOT_CONFIGURED
            break
        case 308:
            code = SwiftFlutterStonePlugin.PINPAD_COMMUNICATION_FAILED
            break
        case 401:
            code = SwiftFlutterStonePlugin.BLUETOOTH_NOT_FOUND
            break
        case 601:
            code = SwiftFlutterStonePlugin.INTERNET_CONNECTION_NOT_FOUND
            break
        default:
            code = SwiftFlutterStonePlugin.UNKNOWN_ERROR
        }
        
        return code
    }
    
    /// Dart Error codes for iOS
    static let UNKNOWN_ERROR = -1
    static let GENERIC_ERROR = 1
    static let PROVIDER_NOT_CONFIGURED = 2
    static let TRANSACTION_AMOUNT_INVALID = 3
    static let TRANSACTION_ABORTED = 4
    static let TRANSACTION_INVALID = 5
    static let TRANSACTION_FAILED = 6
    static let TRANSACTION_EXPIRED = 7
    static let TRANSACTION_DECLINED = 8
    static let TRANSACTION_CANCELLED_BY_USER = 9
    static let PINPAD_CONNECTION_NOT_FOUND = 10
    static let PINPAD_NOT_CONFIGURED = 11
    static let PINPAD_COMMUNICATION_FAILED = 12
    static let BLUETOOTH_NOT_FOUND = 13
    static let INTERNET_CONNECTION_NOT_FOUND = 14
}
