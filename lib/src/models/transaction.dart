part of flutter_stone;

@JsonSerializable()
class Transaction {
  /// Value of this transaction in cents
  /// Tip: Just remove the characters my dude.
  /// Eg: A R$ 10,00 transaction would have an amount of 1000
  final String amount;

  /// Number of instalments for this transaction
  /// has a minimum value of 1 and maximum value of 12
  final int instalmentCount;

  /// Type of this transaction
  /// 1 == DEBIT
  /// 2 == CREDIT
  /// Any other value will throw an exception in your face.
  final int typeOfTransaction;

  /// Name that will show on the client card info
  /// Has a max lenght of 13 characters anything greater than this will throw an exception in your face.
  final String shortName;

  /// UNIQUE identifier for this transaction
  /// Optional since the SDK generates on it's own if not provided
  /// If providing your own, make sure it's UNIQUE
  final String initiatorTransactionKey;

  /// MCC of the sub-merchant which made the transaction
  final String subMerchantCategoryCode;

  /// Sub-merchant's city
  final String subMerchantCity;

  /// Sub-merchant's postal code
  final String subMerchantPostalAddress;

  /// Sub-merchant's identifier on your database
  final String subMerchantRegistedIdentifier;

  /// Sub-merchant's documentation number
  final String subMerchantTaxIdentificationNumber;

  Transaction(
    this.amount, 
    this.instalmentCount, 
    this.typeOfTransaction,
    this.shortName, 
    this.subMerchantCategoryCode,
    this.subMerchantCity,
    this.subMerchantPostalAddress,
    this.subMerchantRegistedIdentifier,
    this.subMerchantTaxIdentificationNumber,
    { 
      this.initiatorTransactionKey 
    }
  ) {
    if(instalmentCount < 1 || instalmentCount > 12)
      throw ArgumentError("Number $instalmentCount of instalments is invalid. Should be between 1 and 12.");

    if(shortName.length > 13)
      throw ArgumentError("ShortName $shortName length is invalid. Should be 13 character maximum.");

    if(typeOfTransaction != 1 && typeOfTransaction != 2)
      throw ArgumentError("TypeOfTransaction $typeOfTransaction is invalid. Should be 1 for DEBIT and 2 for CREDIT");
  }

  static Transaction fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}