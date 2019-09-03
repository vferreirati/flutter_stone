package com.vferreirati.flutter_stone

data class TransactionEvent(
        val errorCode: Int? = null,
        val transactionDate: String? = null,
        val cardBrand: String? = null,
        val cardNumber: String? = null,
        val cardHolderName: String? = null,
        val transactionNumber: String? = null,
        val typeOfTransaction: Int? = null,
        val authorizationCode: String? = null,
        val instalmentCount: Int? = null,
        val transactionStatus: Int? = null
)