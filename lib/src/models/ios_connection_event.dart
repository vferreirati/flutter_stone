part of flutter_stone;

@JsonSerializable()
class IOSConnectionEvent {

  final int errorCode;
  final BluetoothDevice device;
  bool get connectionSuccessful => errorCode == null && device != null;

  IOSConnectionEvent({
    this.device,
    this.errorCode,
  });

  static IOSConnectionEvent fromJson(Map<String, dynamic> json) => _$IOSConnectionEventFromJson(json);
  Map<String, dynamic> toJson() => _$IOSConnectionEventToJson(this);
}