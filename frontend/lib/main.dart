import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:string_validator/string_validator.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Management App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Account Management App')),
        body: BodyWidget(),
      ),
    );
  }
}

class BodyWidget extends StatefulWidget {
  @override
  BodyWidgetState createState() {
    return new BodyWidgetState();
  }
}

class BodyWidgetState extends State<BodyWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final List<TransactionEntry> transactions = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 500,
          child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      validator: _accountIdValidator,
                      controller: _accountController,
                      decoration: InputDecoration(hintText: 'Account Id'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      validator: _amountValidator,
                      controller: _amountController,
                      decoration: InputDecoration(hintText: 'Amount'),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RaisedButton(
                        child: Text('Submit new transaction'),
                        onPressed: () {
                          if (!_formKey.currentState.validate()) {
                            Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text('Fix form validation issues')));
                            return;
                          } else {
                            Scaffold.of(context).showSnackBar(
                                SnackBar(content: Text('Processing data')));
                          }
                          _getAccountBalance(_accountController.text)
                              .then((balance) {
                            _createTransaction(_accountController.text,
                                    _amountController.text, balance)
                                .then((value) => setState(() {
                                      if (value != null) {
                                        transactions.insert(0, value);
                                      }
                                    }));
                            _amountController.clear();
                            _accountController.clear();
                          });
                        },
                      )),
                  Padding(padding: const EdgeInsets.all(8.0)),
                  Text('Recently submitted transactions:'),
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ListView.builder(
                            itemCount: transactions.length,
                            shrinkWrap: true,
                            itemBuilder: (BuildContext ctxt, int index) {
                              return Container(
                                  height: 50,
                                  child: Center(
                                      child: buildTransactionEntryView(index)));
                            })
                      ])),
                ],
              )),
        ),
      ),
    );
  }

  String _accountIdValidator(value) {
    if (value.isEmpty || !isUUID(value)) {
      return 'Please enter a UUID';
    }
    return null;
  }

  String _amountValidator(value) {
    if (value.isEmpty || !isNumeric(value)) {
      return 'Please enter a number';
    }
    return null;
  }

  Widget buildTransactionEntryView(int index) {
    TransactionEntry transaction = transactions[index];
    return Expanded(
        child: Container(
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: SizedBox(
                width: 500,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  transaction.amount < 0
                      ? Text("Withdrew \$" +
                          transaction.amount.toString() +
                          " from " +
                          transaction.accountId +
                          ".")
                      : Text("Transferred \$" +
                          transaction.amount.toString() +
                          " to " +
                          transaction.accountId +
                          "."),
                  Text("Current " +
                      transaction.accountId +
                      "'s balance is \$" +
                      transaction.balance.toString())
                ]))));
  }

  Future<int> _getAccountBalance(String accountId) async {
    return await get("http://localhost:3000/api/balance/" + accountId)
        .then((response) {
      if (response.statusCode == 200) {
        Map<String, dynamic> decoded = json.decode(response.body);

        if (decoded.containsKey("balance") && decoded["balance"] is int) {
          return decoded["balance"];
        }
      }
      return 0;
    });
  }

  Future<TransactionEntry> _createTransaction(
      String accountId, String amountString, int balance) async {
    var amount = int.parse(amountString);

    return await http
        .post('http://localhost:3000/api/amount',
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Transaction-Id': Uuid().v4()
            },
            body: jsonEncode(
                <String, dynamic>{'account_id': accountId, 'amount': amount}))
        .then((response) {
      if (response.statusCode == 200) {
        return TransactionEntry(
            accountId: accountId, amount: amount, balance: balance + amount);
      } else {
        return null;
      }
    });
  }
}

class Transaction {
  final String accountId;
  final int amount;

  Transaction({this.accountId, this.amount});

  toJson() {
    return '{"account_id": "$accountId", "amount": $amount}';
  }
}

class TransactionEntry {
  final String accountId;
  final int amount;
  final int balance;

  TransactionEntry({this.accountId, this.amount, this.balance});
}
