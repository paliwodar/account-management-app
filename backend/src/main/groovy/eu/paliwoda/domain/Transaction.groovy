package eu.paliwoda.domain

import groovy.transform.Canonical

@Canonical
class Transaction {

    String transactionId;
    String accountId;
    long amount;

}
