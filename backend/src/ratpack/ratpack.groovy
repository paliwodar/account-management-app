import eu.paliwoda.api.TransactionDto
import eu.paliwoda.domain.Transaction
import eu.paliwoda.modules.TransactionsModule
import eu.paliwoda.services.AccountService
import eu.paliwoda.services.TransactionService
import ratpack.exec.Blocking
import ratpack.groovy.sql.SqlModule
import ratpack.handling.HandlerDecorator
import ratpack.hikari.HikariModule

import static groovy.json.JsonOutput.toJson
import static ratpack.groovy.Groovy.ratpack

ratpack {
    serverConfig {
        port(3000)
    }
    bindings {
        module(HikariModule) { config ->
            config.dataSourceClassName = 'org.h2.jdbcx.JdbcDataSource'
            config.addDataSourceProperty('URL', "jdbc:h2:mem:devDB;INIT=RUNSCRIPT FROM 'src/main/resources/Transactions.ddl'")
        }
        module SqlModule
        module TransactionsModule
        multiBindInstance(
                HandlerDecorator,
                HandlerDecorator.prepend {
                    it.response.headers.add("Access-Control-Allow-Origin", "*")
                    it.response.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE, HEAD")
                    it.response.headers.add("Access-Control-Allow-Headers", "Transaction-Id, custId, appId, Origin, Content-Type, Cookie, X-CSRF-TOKEN, Accept, Authorization, X-XSRF-TOKEN, Access-Control-Allow-Origin")
                    it.response.headers.add("Access-Control-Expose-Headers", "Authorization, authenticated")
                    it.response.headers.add("Access-Control-Max-Age", "1728000")
                    it.response.headers.add("Access-Control-Allow-Credentials", "true")
                    it.response.headers.add("Content-Type", "application/json")
                    it.next()
                }
        )
    }
    handlers { AccountService accountService, TransactionService transactionService ->
        get("api/ping") {
            render "pong"
        }
        get("api/balance/:account_id") {
            def db = [url: 'jdbc:h2:mem:devDB']
            Blocking.get {
                accountService.getBalance(db, pathTokens.account_id)
            }.then {
                if (it.get('balance') != null) {
                    response.status(200).send(toJson(it).toLowerCase())
                } else {
                    response.status(404).send()
                }
            }
        }
        post("api/amount") {
            if (!request.contentType.isJson()) {
                response.status(415).send()
            } else {
                parse(TransactionDto).then { transactionDto ->
                    def transactionId = request.headers.get("Transaction-Id")
                    if (transactionId == null || !transactionDto.isValid()) {
                        response.status(400).send()
                    } else {
                        Transaction transaction = transactionDto.toDomain(transactionId)
                        def db = [url: 'jdbc:h2:mem:devDB']
                        Blocking.get {
                            transactionService.createTransaction(db, transaction)
                        }.then {
                            response.status(200).send()
                        }
                    }
                }
            }
        }
    }
}