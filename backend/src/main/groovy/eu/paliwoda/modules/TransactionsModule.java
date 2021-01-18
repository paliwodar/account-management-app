package eu.paliwoda.modules;

import eu.paliwoda.services.AccountService;
import eu.paliwoda.services.TransactionService;
import com.google.inject.AbstractModule;
import com.google.inject.Scopes;

public class TransactionsModule extends AbstractModule {

    @Override
    protected void configure() {
        bind(AccountService.class).in(Scopes.SINGLETON);
        bind(TransactionService.class).in(Scopes.SINGLETON);
    }
}
