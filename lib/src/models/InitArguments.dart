part of flutter_stone;

@JsonSerializable()
class InitArguments {
  final ModeEnum mode;
  final String stoneCode;

  InitArguments(this.stoneCode, this.mode);

  static InitArguments fromJson(Map<String, dynamic> json) => _$InitArgumentsFromJson(json);
  Map<String, dynamic> toJson() => _$InitArgumentsToJson(this);
}