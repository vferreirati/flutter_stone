part of flutter_stone;

class FlutterStone {
  static const MethodChannel _channel = const MethodChannel('flutter_stone');
  static const EventChannel _queryChannel = const EventChannel('query_channel');
  static bool _isIosConnected = false;

  FlutterStone._();

  /// Starts the bluetooth query plugin by getting the BluetoothAdapter instance
  /// Returns false if the device doesn't support bluetooth
  static Future<bool> initializeBluetooth() async {
    return await _channel.invokeMethod('initializeBluetooth');
  }

  /// Check if the device bluetooth is turned on
  static Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod('isBluetoothEnabled');
  }

  /// Asks the user to turn the bluetooth on
  static Future<bool> askToTurnBluetoothOn() async {
    return await _channel.invokeMethod('askToTurnBluetoothOn');
  }

  /// Check if the application has access to the devices GPS
  static Future<bool> checkLocationPermission() async {
    return await _channel.invokeMethod('checkLocationPermission');
  }

  /// Asks the user for Location permission
  static Future<bool> askLocationPermission() async {
    return await _channel.invokeMethod('askLocationPermission');
  }

  /// Starts the bluetooth query on the device.
  /// Emits a new value on the stream on new devices found
  static Stream<BluetoothDevice> startScan() async* {
    _channel.invokeMethod('startScan');

    yield* _queryChannel.receiveBroadcastStream()
        .map((jsonString) => BluetoothDevice.fromJson(json.decode(jsonString)));
  }

  /// Starts the Stone SDK with the supplied arguments
  /// Returns if the sdk was started
  static Future<bool> startPlugin(InitArguments arguments) async {
    return await _channel.invokeMethod('startStoneSdk', json.encode(arguments.toJson()));
  }

  /// Attempts to connect to the supplied BluetoothDevice
  /// This method should only be called from a Android Host
  /// Returns the connection event
  static Future<ConnectionEvent> connectToDeviceAndroid(BluetoothDevice device) async {
    final jsonString = json.encode(device.toJson());
    final resultString = await _channel.invokeMethod('connectToDevice', jsonString);
    
    return ConnectionEvent.fromJson(json.decode(resultString));
  }

  /// Attempts to establish a session with the current connected device
  /// This method should be only called from a iOS Host.
  /// returns the connection event
  static Future<ConnectionEvent> connectToDeviceIOS() async {
    final resultString = await _channel.invokeMethod('connect');
    final event = ConnectionEvent.fromJson(json.decode(resultString));

    _isIosConnected = event.connectionSuccessful;

    return event;
  }

  /// Starts a transaction with the supplied
  /// Returns the transaction event
  static Future<TransactionEvent> makeTransaction(Transaction transaction) async {
    final jsonString = jsonEncode(transaction.toJson());

    final resultString = await _channel.invokeMethod('makeTransaction', jsonString);

    return TransactionEvent.fromJson(json.decode(resultString));
  }

  /// Writes to the pinpad display
  /// Returns if the operation was successful
  static Future<bool> writeToDisplay(String message) async {
    return await _channel.invokeMethod('writeToDisplay', message);
  }

  /// Retrieves the list of bluetooth devices known by this device
  static Future<List<BluetoothDevice>> getPairedDevices() async {
    final jsonString = await _channel.invokeMethod('getPairedDevices');
    final jsonList = json.decode(jsonString);
    return (jsonList as List).map((map) => BluetoothDevice.fromJson(map)).toList();
  }

  /// Retrives the current connected device 
  /// Or null if no device is found
  static Future<BluetoothDevice> getConnectedDevice() async {
    final jsonString = await _channel.invokeMethod('getConnectedDevice');
    if(jsonString == null)
      return null;
    else {
      final jsonMap = json.decode(jsonString);
      return BluetoothDevice.fromJson(jsonMap);
    }
  }

  static bool isIosConnected() => _isIosConnected;
}
