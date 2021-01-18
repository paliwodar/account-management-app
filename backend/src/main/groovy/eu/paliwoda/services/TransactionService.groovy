package eu.paliwoda.services

import eu.paliwoda.domain.Transaction
import groovy.sql.Sql

class TransactionService {

    def createTransaction(Map db, Transaction transaction) {
        Sql sql = Sql.newInstance(db.url, db.user, db.password)
        def parameters = [transaction.transactionId, transaction.accountId, transaction.amount]
        sql.executeInsert("INSERT INTO TRANSACTIONS VALUES (?, ?,?)", parameters)
    }

}
