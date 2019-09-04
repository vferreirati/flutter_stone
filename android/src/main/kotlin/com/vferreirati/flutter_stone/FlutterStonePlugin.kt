package com.vferreirati.flutter_stone

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import stone.application.StoneStart
import stone.application.enums.ErrorsEnum
import stone.application.enums.InstalmentTransactionEnum
import stone.application.enums.TransactionStatusEnum
import stone.application.enums.TypeOfTransactionEnum
import stone.application.interfaces.StoneCallbackInterface
import stone.database.transaction.TransactionObject
import stone.environment.Environment
import stone.providers.ActiveApplicationProvider
import stone.providers.BluetoothConnectionProvider
import stone.providers.DisplayMessageProvider
import stone.providers.TransactionProvider
import stone.user.UserModel
import stone.utils.PinpadObject
import stone.utils.Stone

class FlutterStonePlugin(
        private val registrar: Registrar
) : MethodCallHandler, PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {

    private val channel = MethodChannel(registrar.messenger(), "flutter_stone")
    private val queryChannel = EventChannel(registrar.messenger(), "query_channel")

    private var currentPinpadObject: PinpadObject? = null
    private var user: List<UserModel>? = null
    private lateinit var btAdapter: BluetoothAdapter
    private var currentRequestResult: Result? = null
    private val gson = Gson()

    /**
     * Stream handler which represents the devices that are found by the bluetooth adapter
     * Saves the reference to the sink when listened to and removes it when removed
     * */
    private val deviceStreamHandler = object: EventChannel.StreamHandler {

        /**
         * Broadcast receiver for BluetoothDevice.ACTION_FOUND broadcasts
         * Adds the device information to the queryStream only and if only if it wasn't found before
         * */
        private val bluetoothReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if(intent.action == BluetoothDevice.ACTION_FOUND) {
                    val device: BluetoothDevice = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)

                    if(device.name != null && device.address != null && foundDevices.find { current -> current.address == device.address } == null) {
                        foundDevices.add(device)
                        devicesEventSink?.success(gson.toJson(FoundDevice(device.name, device.address)))
                    }
                }
            }
        }

        /* Steam sink reference
         * Post devices in this sink to notify the dart side of the application */
        private var devicesEventSink: EventChannel.EventSink? = null

        /* The actual list of devices found
         * Used to filter devices that show up twice */
        private var foundDevices = mutableListOf<BluetoothDevice>()

        override fun onListen(args: Any?, sink: EventChannel.EventSink) {
            registrar.activity().registerReceiver(bluetoothReceiver, IntentFilter(BluetoothDevice.ACTION_FOUND))
            devicesEventSink = sink
        }

        override fun onCancel(args: Any?) {
            registrar.activity().unregisterReceiver(bluetoothReceiver)
            foundDevices.clear()
            devicesEventSink = null
        }
    }

    init {
        channel.setMethodCallHandler(this)
        queryChannel.setStreamHandler(deviceStreamHandler)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startStoneSdk" -> {
                val jsonString: String = call.arguments()
                val arguments = gson.fromJson(jsonString, InitArguments::class.java)
                startStoneSdk(result, arguments)
            }
            "connectToDevice" ->  {
                val jsonString: String = call.arguments()
                val device = gson.fromJson(jsonString, PinpadDevice::class.java)
                connectToDevice(device, result)
            }
            "makeTransaction" -> {
                val jsonString: String = call.arguments()
                val transaction = gson.fromJson(jsonString, Transaction::class.java)
                makeTransaction(transaction, result)
            }
            "writeToDisplay" -> writeToDisplay(call.arguments(), result)
            "initializeBluetooth" -> result.success(initializeBluetooth())
            "isBluetoothEnabled" -> result.success(isBluetoothEnabled())
            "askToTurnBluetoothOn" -> {
                check(currentRequestResult == null) { "Already requesting permission!" }
                currentRequestResult = result
                askToTurnBluetoothOn()
            }
            "checkLocationPermission" -> result.success(checkLocationPermission())
            "askLocationPermission" -> {
                if(currentRequestResult != null)
                    throw IllegalStateException("Already requesting permission!")
                currentRequestResult = result
                askLocationPermission()
            }
            "startScan" -> startScan()
            "getPairedDevices" -> result.success(getPairedDevices())
            "getConnectedDevice" -> result.success(getConnectedDevice())
        }
    }

    /**
     * Starts the StonePlugin
     * returns if the plugin started successfully
     * */
    private fun startStoneSdk(result: Result, arguments: InitArguments) {
        user = StoneStart.init(registrar.context().applicationContext)
        Stone.setAppName("Serveloja")

        if (user == null) {
            val stoneCodeList = listOf(arguments.stoneCode)

            val appProvider = ActiveApplicationProvider(registrar.context().applicationContext)
            appProvider.connectionCallback = object : StoneCallbackInterface {
                override fun onSuccess() {
                    result.success(true)
                }

                override fun onError() {
                    result.success(false)
                }
            }

            appProvider.activate(stoneCodeList)
        } else {
            result.success(true)
        }

        val mode = if(arguments.mode == "SANDBOX") Environment.SANDBOX else Environment.PRODUCTION
        Stone.setEnvironment(mode)
    }

    /**
     * Connects to a pinpad device using its name and address supplied
     * returns if the connection was made successfully
     * */
    private fun connectToDevice(pinpadDevice: PinpadDevice, result: Result) {
        currentPinpadObject = PinpadObject(pinpadDevice.name, pinpadDevice.address, false)

        val connectionProvider = BluetoothConnectionProvider(registrar.activity(), currentPinpadObject)
        connectionProvider.connectionCallback = object: StoneCallbackInterface {
            override fun onSuccess() {
                result.success(gson.toJson(ConnectionEvent()))
            }

            override fun onError() {
                val errors = connectionProvider.listOfErrors
                when {
                    errors.isEmpty() -> {
                        currentPinpadObject = null
                        val event = ConnectionEvent(errorCode = TIME_OUT)
                        result.success(gson.toJson(event))

                    }
                    errors.first() == ErrorsEnum.PINPAD_ALREADY_CONNECTED -> {
                        val device = Stone.getPinpadObjectList().find { p -> p.macAddress == pinpadDevice.address }
                        if(device != null) {
                            currentPinpadObject = device
                            result.success(gson.toJson(ConnectionEvent()))
                        } else {
                            currentPinpadObject = null
                            val error = errors.first()
                            val event = ConnectionEvent(errorCode = mapErrorToErrorCode(error))
                            result.success(gson.toJson(event))
                        }
                    }
                    else -> {
                        currentPinpadObject = null
                        val error = errors.first()
                        val event = ConnectionEvent(errorCode = mapErrorToErrorCode(error))
                        result.success(gson.toJson(event))
                    }
                }
            }
        }

        connectionProvider.execute()
    }

    /**
     * Makes a transaction using the supplied transaction data
     * */
    private fun makeTransaction(transaction: Transaction, result: Result) {
        val transactionObject = TransactionObject()
        transactionObject.amount = transaction.amount
        transactionObject.initiatorTransactionKey = transaction.initiatorTransactionKey
        transactionObject.typeOfTransaction = if(transaction.typeOfTransaction == 1) TypeOfTransactionEnum.DEBIT else TypeOfTransactionEnum.CREDIT
        transactionObject.shortName = transaction.shortName
        transactionObject.subMerchantCity = transaction.subMerchantCity
        transactionObject.subMerchantPostalAddress = transaction.subMerchantPostalAddress
        transactionObject.subMerchantCategoryCode = transaction.subMerchantCategoryCode
        transactionObject.subMerchantRegisteredIdentifier = transaction.subMerchantRegistedIdentifier
        transactionObject.subMerchantTaxIdentificationNumber = transaction.subMerchantTaxIdentificationNumber
        transactionObject.instalmentTransaction = when(transaction.instalmentCount) {
            1 -> InstalmentTransactionEnum.ONE_INSTALMENT
            2 -> InstalmentTransactionEnum.TWO_INSTALMENT_NO_INTEREST
            3 -> InstalmentTransactionEnum.THREE_INSTALMENT_NO_INTEREST
            4 -> InstalmentTransactionEnum.FOUR_INSTALMENT_NO_INTEREST
            5 -> InstalmentTransactionEnum.FIVE_INSTALMENT_NO_INTEREST
            6 -> InstalmentTransactionEnum.SIX_INSTALMENT_NO_INTEREST
            7 -> InstalmentTransactionEnum.SEVEN_INSTALMENT_NO_INTEREST
            8 -> InstalmentTransactionEnum.EIGHT_INSTALMENT_NO_INTEREST
            9 -> InstalmentTransactionEnum.NINE_INSTALMENT_NO_INTEREST
            10 -> InstalmentTransactionEnum.TEN_INSTALMENT_NO_INTEREST
            11 -> InstalmentTransactionEnum.ELEVEN_INSTALMENT_NO_INTEREST
            else -> InstalmentTransactionEnum.TWELVE_INSTALMENT_NO_INTEREST
        }

        val transactionProvider = TransactionProvider(registrar.activeContext(), transactionObject, user?.first(), currentPinpadObject)
        transactionProvider.connectionCallback = object: StoneCallbackInterface {
            override fun onSuccess() {
                result.success(gson.toJson(mapTransactionObjectToTransactionEvent(transactionObject)))
            }

            override fun onError() {
                val errors = transactionProvider.listOfErrors
                if(errors.isEmpty()) {
                    val event = TransactionEvent(errorCode = TIME_OUT)
                    result.success(gson.toJson(event))
                } else {
                    val error = errors.first()
                    val event = TransactionEvent(errorCode = mapErrorToErrorCode(error))
                    result.success(gson.toJson(event))
                }
            }
        }

        transactionProvider.execute()
    }

    /**
     * Maps a Stone.ErrorsEnum to a local integer
     * */
    private fun mapErrorToErrorCode(error: ErrorsEnum): Int = when(error) {
        ErrorsEnum.CONNECTION_NOT_FOUND -> CONNECTION_NOT_FOUND
        ErrorsEnum.PINPAD_CONNECTION_NOT_FOUND -> PINPAD_CONNECTION_NOT_FOUND
        ErrorsEnum.OPERATION_CANCELLED_BY_USER -> OPERATION_CANCELLED_BY_USER
        ErrorsEnum.CARD_REMOVED_BY_USER -> CARD_REMOVED_BY_USER
        ErrorsEnum.INVALID_TRANSACTION -> INVALID_TRANSACTION
        ErrorsEnum.PASS_TARGE_WITH_CHIP -> PASS_TARGE_WITH_CHIP
        ErrorsEnum.INVALID_STONE_CODE_OR_UNKNOWN -> INVALID_STONE_CODE_OR_UNKNOWN
        ErrorsEnum.TRANSACTION_NOT_FOUND -> TRANSACTION_NOT_FOUND
        ErrorsEnum.INVALID_STONECODE -> INVALID_STONE_CODE
        ErrorsEnum.USERMODEL_NOT_FOUND -> USER_MODEL_NOT_FOUND
        ErrorsEnum.CANT_READ_CHIP_CARD -> CANT_READ_CHIP_CARD
        ErrorsEnum.PINPAD_WITHOUT_KEY -> PINPAD_WITHOUT_KEY
        ErrorsEnum.PINPAD_WITHOUT_STONE_KEY -> PINPAD_WITHOUT_STONE_KEY
        ErrorsEnum.PINPAD_ALREADY_CONNECTED -> PINPAD_ALREADY_CONNECTED
        ErrorsEnum.CONNECTIVITY_ERROR -> CONNECTIVITY_ERROR
        ErrorsEnum.SWIPE_INCORRECT -> SWIPE_INCORRECT
        ErrorsEnum.TOO_MANY_CARDS -> TOO_MANY_CARDS
        ErrorsEnum.INTERNAL_ERROR -> INTERNAL_ERROR
        ErrorsEnum.CARD_ERROR -> CARD_ERROR
        ErrorsEnum.CARD_READ_ERROR -> CARD_READ_ERROR
        ErrorsEnum.CARD_READ_TIMEOUT_ERROR -> CARD_READ_TIMEOUT_ERROR
        ErrorsEnum.CARD_READ_CANCELED_ERROR -> CARD_READ_CANCELED_ERROR
        ErrorsEnum.TRANSACTION_OBJECT_NULL_ERROR -> TRANSACTION_OBJECT_NULL_ERROR
        ErrorsEnum.INVALID_AMOUNT -> INVALID_AMOUNT
        ErrorsEnum.SDK_VERSION_OUTDATED -> SDK_VERSION_OUTDATED
        ErrorsEnum.PINPAD_CLOSED_CONNECTION -> PINPAD_CLOSED_CONNECTION
        ErrorsEnum.UNKNOWN_ERROR -> UNKNOWN_ERROR
        ErrorsEnum.ACCEPTOR_REJECTION -> ACCEPTOR_REJECTION
        else -> UNKNOWN_ERROR
    }

    /**
     * Maps a Stone.TransactionObject to a TransactionEvent
     * */
    private fun mapTransactionObjectToTransactionEvent(transactionObject: TransactionObject) = TransactionEvent(
            errorCode = null,
            authorizationCode = transactionObject.authorizationCode,
            transactionDate = transactionObject.date,
            cardBrand = transactionObject.cardBrand.toString(),
            cardNumber = transactionObject.cardHolderNumber,
            cardHolderName = transactionObject.cardHolderName,
            transactionNumber = transactionObject.initiatorTransactionKey,
            typeOfTransaction = if(transactionObject.typeOfTransactionEnum == TypeOfTransactionEnum.DEBIT) 1 else 2,
            instalmentCount = when(transactionObject.instalmentTransaction) {
                InstalmentTransactionEnum.ONE_INSTALMENT -> 1
                InstalmentTransactionEnum.TWO_INSTALMENT_NO_INTEREST -> 2
                InstalmentTransactionEnum.THREE_INSTALMENT_NO_INTEREST -> 3
                InstalmentTransactionEnum.FOUR_INSTALMENT_NO_INTEREST -> 4
                InstalmentTransactionEnum.FIVE_INSTALMENT_NO_INTEREST -> 5
                InstalmentTransactionEnum.SIX_INSTALMENT_NO_INTEREST -> 6
                InstalmentTransactionEnum.SEVEN_INSTALMENT_NO_INTEREST -> 7
                InstalmentTransactionEnum.EIGHT_INSTALMENT_NO_INTEREST -> 8
                InstalmentTransactionEnum.NINE_INSTALMENT_NO_INTEREST -> 9
                InstalmentTransactionEnum.TEN_INSTALMENT_NO_INTEREST -> 10
                InstalmentTransactionEnum.ELEVEN_INSTALMENT_NO_INTEREST -> 11
                else -> 12
            },
            transactionStatus = when(transactionObject.transactionStatus) {
                TransactionStatusEnum.APPROVED -> 1
                else -> 2
            }
    )

    /**
     * Writes the provided message on the pinpad device display
     * */
    private fun writeToDisplay(message: String, result: Result) {
        if(currentPinpadObject == null) {
            result.success(false)
            return
        }

        val displayMessageProvider = DisplayMessageProvider(registrar.activity(), message, currentPinpadObject)
        displayMessageProvider.execute()
        result.success(true)
    }

    /**
     * Starts the bluetooth query plugin by getting the BluetoothAdapter instance
     * Returns false if the device doesn't support bluetooth
     * */
    private fun initializeBluetooth(): Boolean {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if(adapter != null) {
            btAdapter = adapter
        }

        return adapter != null
    }

    /**
     * Check if the device bluetooth is turned on
     * */
    private fun isBluetoothEnabled(): Boolean = btAdapter.isEnabled

    /**
     * Asks the user to turn the bluetooth on
     * */
    private fun askToTurnBluetoothOn() {
        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        registrar.activity().startActivityForResult(intent, CODE_TURN_BLUETOOTH_ON)
    }

    /**
     * Check if the application has access to the devices GPS
     * */
    private fun checkLocationPermission() = ContextCompat.checkSelfPermission(registrar.activity(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    /**
     * Asks the user for Location permission
     * */
    private fun askLocationPermission() {
        ActivityCompat.requestPermissions(registrar.activity(), arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION), REQUEST_LOCATION_PERMISSION)
    }

    /**
     * Start scanning for devices
     * */
    private fun startScan() = btAdapter.startDiscovery()

    /**
     * Gets and returns the list of bluetooth devices bonded to this device
     * */
    private fun getPairedDevices(): String {
        val devices = btAdapter.bondedDevices
        val list = mutableListOf<FoundDevice>()
        for(device in devices) {
            list.add(FoundDevice(name = device.name, address = device.address))
        }
        return Gson().toJson(list)
    }

    private fun getConnectedDevice(): String? = if(currentPinpadObject == null)
        null
    else
        Gson().toJson(PinpadDevice(name = currentPinpadObject!!.name, address = currentPinpadObject!!.macAddress))

    /**
     * Android callback
     * */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when(requestCode) {
            CODE_TURN_BLUETOOTH_ON -> {
                currentRequestResult?.success(resultCode == Activity.RESULT_OK)
                currentRequestResult = null
                true
            }
            else -> false
        }
    }

    /**
     * Android callback
     * */
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
        return when(requestCode) {
            REQUEST_LOCATION_PERMISSION -> {
                currentRequestResult?.success(grantResults != null && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
                currentRequestResult = null
                true
            }
            else -> false
        }
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val pluginInstance = FlutterStonePlugin(registrar)
            registrar.addActivityResultListener(pluginInstance)
            registrar.addRequestPermissionsResultListener(pluginInstance)
        }

        private const val CODE_TURN_BLUETOOTH_ON = 100

        private const val REQUEST_LOCATION_PERMISSION = 200

        /**
         * Most of the errors from the StoneSDK mapped to integer values
         * */
        const val TIME_OUT = 1
        const val CONNECTION_NOT_FOUND = 2
        const val PINPAD_CONNECTION_NOT_FOUND = 3
        const val OPERATION_CANCELLED_BY_USER = 4
        const val CARD_REMOVED_BY_USER = 5
        const val INVALID_TRANSACTION = 6
        const val PASS_TARGE_WITH_CHIP = 7
        const val INVALID_STONE_CODE_OR_UNKNOWN = 8
        const val TRANSACTION_NOT_FOUND = 9
        const val INVALID_STONE_CODE = 10
        const val USER_MODEL_NOT_FOUND = 11
        const val CANT_READ_CHIP_CARD = 12
        const val PINPAD_WITHOUT_KEY = 13
        const val PINPAD_WITHOUT_STONE_KEY = 14
        const val PINPAD_ALREADY_CONNECTED = 15
        const val CONNECTIVITY_ERROR = 16
        const val SWIPE_INCORRECT = 17
        const val TOO_MANY_CARDS = 18
        const val UNKNOWN_ERROR = 19
        const val INTERNAL_ERROR = 21
        const val CARD_ERROR = 22
        const val CARD_READ_ERROR = 23
        const val CARD_READ_TIMEOUT_ERROR = 24
        const val CARD_READ_CANCELED_ERROR = 25
        const val TRANSACTION_OBJECT_NULL_ERROR = 26
        const val INVALID_AMOUNT = 27
        const val SDK_VERSION_OUTDATED = 28
        const val PINPAD_CLOSED_CONNECTION = 29
        const val ACCEPTOR_REJECTION = 30
    }
}
