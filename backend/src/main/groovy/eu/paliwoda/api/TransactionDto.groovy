package eu.paliwoda.api

import eu.paliwoda.domain.Transaction

class TransactionDto {

    String account_id
    String amount

    def isValid() {
        account_id != null && amount != null && amount.isLong()
    }

    def toDomain(def transactionId) {
        new Transaction(transactionId: transactionId, accountId: account_id, amount: amount.toLong())
    }

}
