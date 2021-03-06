component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="settings" inject="coldbox:setting:vindicia";
	property name="LogService" inject="LogService@cashbox";

	function getTransaction() provider="Transaction@cashbox" {}

	string function createTransactionID() {
		return settings.txnprefix & "X" & dateTimeFormat(now(),"yyyymmddHHNNssLLL");
	}

	struct function authCapture(required string id, required string ip, required string accountID, required string paymentmethodID, required array products, string affiliateID="", string currency="USD", string billingStatementID, boolean sendEmailNotification=false, numeric minChargebackProbability=100) {
		arguments.authOnly = false;
		return auth( argumentCollection = arguments );
	}

	struct function auth(required string id, required string ip, required string accountID, required string paymentmethodID, required array products, string affiliateID="", string currency="USD", string billingStatementID, boolean sendEmailNotification=false, numeric minChargebackProbability=100, boolean authOnly=true) {
		var classVersion = Factory.getClassVersion();
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

		if (!isempty(arguments.affiliateID))
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
				result.return = Transaction.authCapture("", arguments.sendEmailNotification, true, false, "", false, arguments.minChargebackProbability)
			}
			result.soapID = result.return.getReturnObject().getSoapID();
			result.transactionObj = Transaction;
			result.transaction = getTransaction().populate( Transaction );

			if (result.transactionObj.getStatusLog(0).getStatus().getValue()!="Authorized") {
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

		local.details = {"merchantAccountID":arguments.accountID, "products":arguments.products, "authOnly":arguments.authOnly, "merchantPaymentMethodID":arguments.paymentmethodID, "merchantTransactionID":arguments.id}
		LogService.log( result.soapID, "Transaction", arguments.authOnly?"auth":"authCapture", result.code, result.message, local.details );
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

		local.details = {"transactionIDs":arguments.transactionIDs}

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

		LogService.log( result.soapID, "Transaction", "capture", result.code, result.message, local.details );		

		return result;
	}

	struct function refund(required string transactionID, numeric amount, string note) {
		var Transaction = Factory.get("com.vindicia.client.Transaction");
		var Refund = Factory.get("com.vindicia.client.Refund");
		var RefundClient = Factory.get("com.vindicia.client.Refund");

		Transaction.setMerchantTransactionID(arguments.transactionID);

		Refund.setTransaction( Transaction );
		Refund.setAmount( javacast("java.math.BigDecimal",arguments.amount) );
		
		if (!isnull(arguments.note))
			Refund.setNote( arguments.note );

		var e;
		var result = { message:"OK", code:200 }

		local.details = {"transactionID":arguments.transactionID, "amount":arguments.amount, "note":arguments.note}

		try {
			result.refunds = RefundClient.perform( "", [ Refund ] );
			result.refund = result.refunds[1];
			result.success = (result.refund.getStatus().getValue() != "Failed");
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "Refund", "perform", e.returncode, e.message, local.details );		
			rethrow;
		}

		return result;		
	}

	array function fetchDeltaSince(required date tsDelta, required numeric page, required numeric pageSize, date tsEnd=now()) {
		var result = [];
		var Transaction = Factory.get("com.vindicia.client.Transaction");
		var e;

		local.start = createobject("java","java.util.GregorianCalendar");
		local.end = createobject("java","java.util.GregorianCalendar");

		local.start.setTime( arguments.tsDelta );
		local.end.setTime( arguments.tsEnd );

		try {
			// java.lang.String srd, java.util.Calendar timestamp, java.util.Calendar endTimestamp, java.lang.Integer page, java.lang.Integer pageSize, PaymentMethod paymentMethod
			var response = Transaction.fetchDeltaSince("", local.start, local.end, arguments.page, arguments.pageSize, nullValue());
			for (local.txn in (response?:[])) {
				result.append( getTransaction().populate(local.txn) );
			}

			return result;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "Transaction", "fetchDeltaSince", e.returnCode, e.message );		
			rethrow;
		}
	}

	array function fetchByAccount(required string accountID, required numeric page, required numeric pageSize) {
		var result = [];
		var Transaction = Factory.get("com.vindicia.client.Transaction");
		var e;

		var Account = Factory.get("com.vindicia.client.Account");
		Account.setMerchantAccountID( arguments.accountID );

		try {
			// java.lang.String srd, Account account, java.lang.Boolean includeChildren, java.lang.Integer page, java.lang.Integer pageSize
			var response = Transaction.fetchByAccount("", Account, false, arguments.page, arguments.pageSize);
			for (local.txn in (response?:[])) {
				result.append( getTransaction().populate(local.txn) );
			}

			return result;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "Transaction", "fetchByAccount", e.returnCode, e.message );		
			rethrow;
		}
	}
}