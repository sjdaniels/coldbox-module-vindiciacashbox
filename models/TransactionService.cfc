component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="settings" inject="coldbox:setting:vindicia";
	property name="LogService" inject="LogService@cashbox";

	struct function authCapture(required string id, required string ip, required string accountID, required string paymentmethodID, required array products, string affiliateID="", string currency="USD", string billingStatementID, boolean sendEmailNotification=false, numeric minChargebackProbability=100) {
		arguments.authOnly = false;
		return auth( argumentCollection = arguments );
	}

	struct function auth(required string id, required string ip, required string accountID, required string paymentmethodID, required array products, string affiliateID="", string currency="USD", string billingStatementID, boolean sendEmailNotification=false, numeric minChargebackProbability=100, boolean authOnly=true) {
		var ClientConstants = Factory.get("com.vindicia.client.ClientConstants");
		var classVersion = "v#replace(ClientConstants.getVersion(),'.','_','all')#";
		var Transaction = Factory.get("com.vindicia.client.Transaction");
		var e;

		Transaction.setMerchantTransactionID( arguments.id );
		Transaction.setSourceIP( arguments.ip );
		Transaction.setCurrency( arguments.currency );

		var Account = Factory.get("com.vindicia.client.Account");
		Account.setMerchantAccountID( arguments.accountID );
		Transaction.setAccount( Account );

		var PaymentMethod = Factory.get("com.vindicia.client.PaymentMethod");
		PaymentMethod.setMerchantPaymentMethodID( arguments.paymentmethodID );
		Transaction.setSourcePaymentMethod( PaymentMethod );

		if (!isnull(arguments.affiliateID))
			Transaction.setMerchantAffiliateID( arguments.affiliateID );

		if (!isnull(arguments.billingStatementID)) {
			Transaction.setBillingStatementIdentifier( arguments.billingStatementID );
		}

		var Items = [];
		for (var lineitem in arguments.products) {
			local.Item = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.TransactionItem");
			local.Item.setSku( lineitem.sku );
			local.Item.setName( lineitem.name );
			local.Item.setPrice( javacast("java.math.BigDecimal",lineitem.price) );
			local.Item.setQuantity( javacast("java.math.BigDecimal",lineitem.quantity) );

			Items.append( local.Item );
		}

		Transaction.setTransactionItems( Items );

		var result = { message:"OK", code:200, success:true }

		try {
			if (arguments.authOnly) {
				// java.lang.String srd, int minChargebackProbability, java.lang.Boolean sendEmailNotification, java.lang.String campaignCode, java.lang.Boolean dryrun
				result.return = Transaction.auth("", arguments.minChargebackProbability, arguments.sendEmailNotification, "", false)
			} else {
				// java.lang.String srd, java.lang.Boolean sendEmailNotification, java.lang.Boolean ignoreAvsPolicy, java.lang.Boolean ignoreCvnPolicy, java.lang.String campaignCode, java.lang.Boolean dryrun, int minChargebackProbability
				result.return = Transaction.authCapture("", arguments.sendEmailNotification, false, false, "", false, arguments.minChargebackProbability)
			}
			result.soapID = result.return.getReturnObject().getSoapID();
			result.transaction = Transaction;

			if (result.transaction.getStatusLog(0).getStatus().getValue()!="Authorized") {
				result.code = 400;
				result.message = "Transaction Not Authorized";
				result.success = false;
			}
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			result.code = e.returncode;
			result.message = e.message;
			result.success = false;
			result.soapID = e.soapID;
		}

		LogService.log( result.soapID, "Transaction", arguments.authOnly?"auth":"authCapture", result.code, result.message );
		return result;
	}

	struct function capture(required any transactionIDs) {
		var Transaction = Factory.get("com.vindicia.client.Transaction");
		var Transactions = [];
		if (!isArray(arguments.transactionIDs)) {
			Transactions.append(Transaction.fetchByMerchantTransactionID("",arguments.transactionIDs));
		} else {
			for (local.txnID in arguments.transactionIDs) {
				Transactions.append(Transaction.fetchByMerchantTransactionID("",local.txnID));
			}
		}

		var e;
		var result = { message:"OK", code:200 }

		try {
			result.return = Transaction.capture("", Transactions);
			result.soapID = result.return.getReturnObject().getSoapID();
			result.captureResults = result.return.getResults();
			result.transactions = Transactions;
			result.success = [];
			for (local.cr in result.captureResults) {
				result.success.append((local.cr.getReturnCode()=="200"));
			}
			if (!isArray(arguments.transactionIDs)) {
				// add singular version
				result.captureResult = result.captureResults[1];
				result.transaction = Transactions[1];
				result.success = (result.captureResult.getReturnCode()=="200");
				structdelete(result,"captureResults");
				structdelete(result,"transactions");
			}
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			result.code = e.returncode;
			result.message = e.message;
			result.success = false;
			result.soapID = e.soapID;
		}

		LogService.log( result.soapID, "Transaction", "capture", result.code, result.message );		

		return result;
	}
}