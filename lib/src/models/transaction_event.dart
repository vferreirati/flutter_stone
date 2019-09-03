part of flutter_stone;

@JsonSerializable()
class TransactionEvent {
  final int errorCode;
  final String transactionDate;
  final String cardBrand;
  final String cardNumber;
  final String cardHolderName;
  final String transactionNumber;
  final int typeOfTransaction;
  final String authorizationCode;
  final int instalmentCount;
  final int transactionStatus;

  TransactionEvent(this.errorCode, this.transactionDate, this.cardBrand, this.cardNumber, this.cardHolderName, this.transactionNumber, this.typeOfTransaction, this.authorizationCode, this.instalmentCount, this.transactionStatus);

  static TransactionEvent fromJson(Map<String, dynamic> json) => _$TransactionEventFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionEventToJson(this);
}