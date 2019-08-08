part of flutter_stone;

@JsonSerializable()
class BluetoothDevice {
  final String name;
  final String address;

  BluetoothDevice(this.name, this.address);

  static BluetoothDevice fromJson(Map<String, dynamic> json) => _$BluetoothDeviceFromJson(Map<String, dynamic>.from(json));
  Map<String, dynamic> toJson() => _$BluetoothDeviceToJson(this);
}