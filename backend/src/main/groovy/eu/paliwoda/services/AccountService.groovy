package eu.paliwoda.services

import groovy.sql.Sql

class AccountService {

    def getBalance(db, String accountId) {

        def sql = Sql.newInstance(db.url, db.user, db.password)
        sql.firstRow("SELECT SUM(AMOUNT) as balance FROM TRANSACTIONS WHERE ACCOUNT_ID = $accountId")
    }
}
