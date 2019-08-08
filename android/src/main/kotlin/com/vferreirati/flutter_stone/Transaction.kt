package com.vferreirati.flutter_stone

data class Transaction(
        val amount: String,
        val instalmentCount: Int,
        val typeOfTransaction: Int,
        val shortName: String,
        val initiatorTransactionKey: String?,
        val subMerchantCategoryCode: String,
        val subMerchantCity: String,
        val subMerchantPostalAddress: String,
        val subMerchantRegistedIdentifier: String,
        val subMerchantTaxIdentificationNumber: String
)