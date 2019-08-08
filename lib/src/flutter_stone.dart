part of flutter_stone;

class FlutterStone {
  static const MethodChannel _channel = const MethodChannel('flutter_stone');

  static Future<bool> startPlugin(InitArguments arguments) async {
    return await _channel.invokeMethod('startPlugin', json.encode(arguments.toJson()));
  }

  static Future<ConnectionEvent> connectToDeviceAndroid(BluetoothDevice device) async {
    final jsonString = json.encode(device.toJson());
    final resultString = await _channel.invokeMethod('connectToDevice', jsonString);
    
    return ConnectionEvent.fromJson(json.decode(resultString));
  }

  static Future<ConnectionEvent> connectToDeviceIOS() async {
    final resultString = await _channel.invokeMethod('connect');

    return ConnectionEvent.fromJson(json.decode(resultString));
  }

  static Future<TransactionEvent> makeTransaction(Transaction transaction) async {
    final jsonString = jsonEncode(transaction.toJson());

    final resultString = await _channel.invokeMethod('makeTransaction', jsonString);

    return TransactionEvent.fromJson(json.decode(resultString));
  }

  static Future<bool> writeToDisplay(String message) async {
    return await _channel.invokeMethod('writeToDisplay', message);
  }
}
