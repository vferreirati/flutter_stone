part of flutter_stone;

@JsonSerializable()
class ConnectionEvent {
  final int errorCode;
  bool get connectionSuccessful => errorCode == null;

  ConnectionEvent(this.errorCode);

  static ConnectionEvent fromJson(Map<String, dynamic> json) => _$ConnectionEventFromJson(json);
  Map<String, dynamic> toJson() => _$ConnectionEventToJson(this);
}