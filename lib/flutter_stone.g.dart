// GENERATED CODE - DO NOT MODIFY BY HAND

part of flutter_stone;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionEvent _$ConnectionEventFromJson(Map<String, dynamic> json) {
  return ConnectionEvent(
    json['errorCode'] as int,
  );
}

Map<String, dynamic> _$ConnectionEventToJson(ConnectionEvent instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
    };

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return Transaction(
    json['amount'] as String,
    json['instalmentCount'] as int,
    json['typeOfTransaction'] as int,
    json['shortName'] as String,
    json['subMerchantCategoryCode'] as String,
    json['subMerchantCity'] as String,
    json['subMerchantPostalAddress'] as String,
    json['subMerchantRegistedIdentifier'] as String,
    json['subMerchantTaxIdentificationNumber'] as String,
    initiatorTransactionKey: json['initiatorTransactionKey'] as String,
  );
}

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'instalmentCount': instance.instalmentCount,
      'typeOfTransaction': instance.typeOfTransaction,
      'shortName': instance.shortName,
      'initiatorTransactionKey': instance.initiatorTransactionKey,
      'subMerchantCategoryCode': instance.subMerchantCategoryCode,
      'subMerchantCity': instance.subMerchantCity,
      'subMerchantPostalAddress': instance.subMerchantPostalAddress,
      'subMerchantRegistedIdentifier': instance.subMerchantRegistedIdentifier,
      'subMerchantTaxIdentificationNumber':
          instance.subMerchantTaxIdentificationNumber,
    };

TransactionEvent _$TransactionEventFromJson(Map<String, dynamic> json) {
  return TransactionEvent(
    json['errorCode'] as int,
    json['transactionDate'] as String,
    json['cardBrand'] as String,
    json['cardNumber'] as String,
    json['cardHolderName'] as String,
    json['transactionNumber'] as String,
    json['typeOfTransaction'] as int,
    json['authorizationCode'] as String,
    json['instalmentCount'] as int,
  );
}

Map<String, dynamic> _$TransactionEventToJson(TransactionEvent instance) =>
    <String, dynamic>{
      'errorCode': instance.errorCode,
      'transactionDate': instance.transactionDate,
      'cardBrand': instance.cardBrand,
      'cardNumber': instance.cardNumber,
      'cardHolderName': instance.cardHolderName,
      'transactionNumber': instance.transactionNumber,
      'typeOfTransaction': instance.typeOfTransaction,
      'authorizationCode': instance.authorizationCode,
      'instalmentCount': instance.instalmentCount,
    };

InitArguments _$InitArgumentsFromJson(Map<String, dynamic> json) {
  return InitArguments(
    json['stoneCode'] as String,
    _$enumDecodeNullable(_$ModeEnumEnumMap, json['mode']),
  );
}

Map<String, dynamic> _$InitArgumentsToJson(InitArguments instance) =>
    <String, dynamic>{
      'mode': _$ModeEnumEnumMap[instance.mode],
      'stoneCode': instance.stoneCode,
    };

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source);
}

const _$ModeEnumEnumMap = <ModeEnum, dynamic>{
  ModeEnum.SANDBOX: 'SANDBOX',
  ModeEnum.PRODUCTION: 'PRODUCTION'
};

BluetoothDevice _$BluetoothDeviceFromJson(Map<String, dynamic> json) {
  return BluetoothDevice(
    json['name'] as String,
    json['address'] as String,
  );
}

Map<String, dynamic> _$BluetoothDeviceToJson(BluetoothDevice instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address,
    };
