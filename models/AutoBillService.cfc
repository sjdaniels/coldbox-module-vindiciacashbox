component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="settings" inject="coldbox:setting:vindicia";
	property name="LogService" inject="LogService@cashbox";

	function getTransaction() provider="Transaction@cashbox" {}
	function getRefund() provider="Refund@cashbox" {}

	struct function update(required string id, required string ip, required string accountID, required string paymentmethodID, required string productID, string affiliateID="", string currency="USD", string billingStatementID, numeric minChargebackProbability=100) {
		var classVersion = Factory.getClassVersion();
		var AutoBill = Factory.get("com.vindicia.client.AutoBill");
		var e;

		AutoBill.setMerchantAutoBillID( arguments.id );
		AutoBill.setSourceIP( arguments.ip );
		AutoBill.setCurrency( arguments.currency );

		var Account = Factory.get("com.vindicia.client.Account");
		Account.setMerchantAccountID( arguments.accountID );
		AutoBill.setAccount( Account );

		var PaymentMethod = Factory.get("com.vindicia.client.PaymentMethod");
		PaymentMethod.setMerchantPaymentMethodID( arguments.paymentmethodID );
		AutoBill.setPaymentMethod( PaymentMethod );
		
		var Item = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.AutoBillItem");
		var Product = Factory.get("com.vindicia.client.Product");

		Product.setMerchantProductID( arguments.productID );

		Item.setMerchantAutoBillItemID( createuuid() );
		Item.setProduct( Product );
		AutoBill.setItems( [Item] );

		if (!isnull(arguments.affiliateID))
			AutoBill.setMerchantAffiliateID( arguments.affiliateID );

		if (!isnull(arguments.billingStatementID)) {
			AutoBill.setBillingStatementIdentifier( arguments.billingStatementID );
		}

		var IAFP = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.ImmediateAuthFailurePolicy").putAutoBillInRetryCycleIfPaymentMethodIsValid;
		var result = { message:"OK", code:200, success:true }

		try {
			result.return = AutoBill.update("", IAFP, true, arguments.minChargebackProbability, false, false, "", false, "");
			result.soapID = result.return.getReturnObject().getSoapID();
			result.autobill = AutoBill;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			result.code = e.returncode;
			result.message = e.message;
			result.success = false;
			result.soapID = e.soapID;
		}

		LogService.log( result.soapID, "AutoBill", "update", result.code, result.message );
	
		return result;
	}

	function getNextBillingDate( required string autobillID ) {
		local.autobill = Factory.get("com.vindicia.client.AutoBill").fetchByMerchantAutobillID("", arguments.autobillID);
		if (isnull(local.autobill))
			return;

		local.nextbilling = local.autobill.getNextBilling();
		if (isnull(local.nextbilling))
			return;

		local.result = local.nextbilling.getTimestamp().getTime();

		return local.result;
	}

	struct function cancel( required string autobillID, boolean disentitle=false, boolean settle=false, boolean sendNotice=false, string reasonCode="" ) {
		var AutoBill = Factory.get("com.vindicia.client.AutoBill").fetchByMerchantAutobillID("", arguments.autobillID);

		var result = { message:"OK", code:200, success:true }
		try {
			// java.lang.String srd, boolean disentitle, boolean force, java.lang.Boolean settle, java.lang.Boolean sendCancellationNotice, java.lang.String cancelReasonCode
			result.return = AutoBill.cancel("", arguments.disentitle, false, arguments.settle, arguments.sendNotice, arguments.reasonCode);
			result.soapID = result.return.getReturnObject().getSoapID();
			result.autobill = AutoBill;
			result.dateExpires = AutoBill.getEndTimestamp().getTime();
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			result.code = e.returncode;
			result.message = e.message;
			result.success = false;
			result.soapID = e.soapID;
		}

		LogService.log( result.soapID, "AutoBill", "cancel", result.code, result.message );
		return result;
	}

	struct function resume( required string autobillID ) {
		var classVersion = Factory.getClassVersion();
		var AutoBill = Factory.get("com.vindicia.client.AutoBill").fetchByMerchantAutobillID("", arguments.autobillID);

		if (AutoBill.getStatus().getValue() != "Pending Cancel") {
			throw("AutoBill #arguments.autobillID# can not be resumed - status is #AutoBill.getStatus().getValue()#");
		}

		// this uses a hack to restart existing AutoBills. Not guaranteed to continue to work if Vindicia changes something...
		var AutoBillStatus = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.AutoBillStatus").fromString("Active");
		AutoBill.setStatus( AutoBillStatus );

		var result = { message:"OK", code:200, success:true }

		try {
			result.return = AutoBill.update("", nullValue(), false, 100, true, true, "", false, "");
			result.soapID = result.return.getReturnObject().getSoapID();
			result.autobill = AutoBill;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "AutoBill", "update", e.returncode, e.message );
			rethrow;
		}

		LogService.log( result.soapID, "AutoBill", "update", result.code, result.message );
		return result;
	}

	struct function modify( required string autobillID, boolean prorate=true, string effectiveDate="today", string replaceBillingPlan, array replaceProducts=[], boolean dryrun=false ) {
		var classVersion = Factory.getClassVersion();
		var AutoBill = Factory.get("com.vindicia.client.AutoBill").fetchByMerchantAutobillID("", arguments.autobillID);
		var ItemModifications = [];

		for (local.replaceProduct in arguments.replaceProducts) {
			var RemoveProduct = Factory.get("com.vindicia.client.Product");
			RemoveProduct.setMerchantProductID( local.replaceProduct.remove );
			var RemoveItem = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.AutoBillItem");
			RemoveItem.setProduct( RemoveProduct );

			var AddProduct = Factory.get("com.vindicia.client.Product").fetchByMerchantProductID("", local.replaceProduct.add);
			var AddItem = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.AutoBillItem");
			AddItem.setProduct( AddProduct );
		
			var Modification = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.AutoBillItemModification");
			Modification.setRemoveAutobillItem( RemoveItem );
			Modification.setAddAutobillItem( AddItem );
		
			ItemModifications.append( Modification );
		}

		var NewBillingPlan;
		if (!isnull(arguments.replaceBillingPlan)) {
			NewBillingPlan = Factory.get("com.vindicia.client.BillingPlan").fetchByMerchantBillingPlanID("", arguments.replaceBillingPlan);
		}

		if (isnull(arguments.replaceBillingPlan) && arguments.replaceProducts.len()==1) {
		// set the new billingplan to the default for the new product
			NewBillingPlan = Factory.get("com.vindicia.client.BillingPlan").fetchByMerchantBillingPlanID("", AddProduct.getDefaultBillingPlan().getMerchantBillingPlanID());
		}

		var result = { message:"OK", code:200, success:true }
		try {
			// java.lang.String srd, boolean billProratedPeriod, java.lang.String effectiveDate, BillingPlan changeBillingPlanTo, AutoBillItemModification[] autoBillItemModifications, java.lang.Boolean dryrun
			// valid values for effectiveDate are "today" and "nextBill"
			result.return = AutoBill.modify("", arguments.prorate, arguments.effectiveDate, NewBillingPlan?:nullValue(), ItemModifications, arguments.dryrun);
			result.soapID = result.return.getReturnObject().getSoapID();
			result.autobill = AutoBill;
			result.dateNextBilling = AutoBill.getNextBilling().getTimestamp().getTime();

			if (!isnull(result.return.getTransaction()))
				result.transaction = getTransaction().populate( result.return.getTransaction() );
			
			result.refunds = [];
			if (!isnull(result.return.getRefunds())) {
				for (local.refund in result.return.getRefunds()) {
					result.refunds.append( getRefund().populate( local.refund ) );
				}
			}
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			result.code = e.returncode;
			result.message = e.message;
			result.success = false;
			result.soapID = e.soapID;
			LogService.log( result.soapID, "AutoBill", "modify", result.code, result.message );
			rethrow;
		}

		LogService.log( result.soapID, "AutoBill", "modify", result.code, result.message );
		return result;
	}

	struct function migrate( required string id, required string accountID, required string productID, required date dateStarted, required struct lastTransaction, required numeric billingCycle, date dateNextBilling, string affiliateID="", string currency="USD", string billingStatementID ) {
		var classVersion = Factory.getClassVersion();
		var AutoBill = Factory.get("com.vindicia.client.AutoBill");
		var e;

		AutoBill.setMerchantAutoBillID( arguments.id );
		AutoBill.setCurrency( arguments.currency );
		AutoBill.setStartTimestamp( arguments.dateStarted );

		var Account = Factory.get("com.vindicia.client.Account");
		Account.setMerchantAccountID( arguments.accountID );
		AutoBill.setAccount( Account );

		var Item = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.AutoBillItem");
		var Product = Factory.get("com.vindicia.client.Product");

		Product.setMerchantProductID( arguments.productID );

		Item.setMerchantAutoBillItemID( createuuid() );
		Item.setProduct( Product );
		AutoBill.setItems( [Item] );

		if (!isnull(arguments.affiliateID))
			AutoBill.setMerchantAffiliateID( arguments.affiliateID );

		if (!isnull(arguments.billingStatementID)) {
			AutoBill.setBillingStatementIdentifier( arguments.billingStatementID );
		}

		var TxnItem = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.MigrationTransactionItem");
		var TxnItemType = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.MigrationTransactionItemType").fromString("RecurringCharge");
		TxnItem.setItemType(TxnItemType);
		TxnItem.setName( arguments.lastTransaction.productname );
		TxnItem.setPrice( javacast("java.math.BigDecimal", arguments.lastTransaction.price) );
		TxnItem.setServicePeriodStartDate( arguments.lastTransaction.dateCreated );
		TxnItem.setServicePeriodEndDate( arguments.lastTransaction.datePeriodEnds );
		TxnItem.setSku( arguments.productID );

		var creditCardStatusA = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.TransactionStatusCreditCard");
		var statusLog = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.TransactionStatus");
		var PaymentMethodType = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.PaymentMethodType").fromString("CreditCard");
		var PaymentStatus = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.TransactionStatusType").fromString("Captured");
		creditCardStatus.setAuthCode('000');
		statusLog.setCreditCardStatus(creditCardStatus);
		statusLog.setPaymentMethodType(PaymentMethodType);
		statusLog.setStatus(PaymentStatus);
		statusLog.setTimestamp(arguments.lastTransaction.dateCreated);

		var migrationTransaction = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.MigrationTransaction")
		var TransactionType = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.MigrationTransactionType").fromString("Recurring");
		migrationTransaction.setAccount(Account);
		migrationTransaction.setMerchantTransactionId(arguments.lastTransaction.id);
		migrationTransaction.setAmount(javacast("java.math.BigDecimal", arguments.lastTransaction.price));
		migrationTransaction.setAutoBillCycle(arguments.billingCycle);
		migrationTransaction.setBillingDate( arguments.lastTransaction.dateCreated );
		migrationTransaction.setBillingPlanCycle(arguments.billingCycle);
		migrationTransaction.setCurrency(arguments.currency);
		// migrationTransaction.setPaymentProcessor($paymentProcessor);
		migrationTransaction.setMerchantBillingPlanId( arguments.lastTransaction.billingPlanID );
		migrationTransaction.setMigrationTransactionItems([ TxnItem ]);
		//migrationTransaction.setPaymentMethod($paymentMethod);
		//migrationTransaction.setShippingAddress($address);
		migrationTransaction.setStatusLog([ statusLog ]);
		migrationTransaction.setType(TransactionType);
		// migrationTransaction.setPaymentProcessorTransactionId($paymentProcessorTransactionId);	
	
		var result = { message:"OK", code:200, success:true }

		if (!isnull(arguments.dateNextBilling)) {
			var nextPeriodStartDate = createobject("java","java.util.GregorianCalendar");
			nextPeriodStartDate.setTime( arguments.dateNextBilling );
		}

		try {
			// java.lang.String srd, java.util.Calendar nextPeriodStartDate, MigrationTransaction[] migrationTransactions, java.lang.String cancelReasonCode
			result.return = AutoBill.migrate("", !isnull(arguments.dateNextBilling) ? nextPeriodStartDate : nullValue(), [migrationTransaction], nullValue());
			result.soapID = result.return.getReturnObject().getSoapID();
			result.autobill = AutoBill;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			result.code = e.returncode;
			result.message = e.message;
			result.success = false;
			result.soapID = e.soapID;
		}

		LogService.log( result.soapID, "AutoBill", "migrate", result.code, result.message );	
		return result;
	}
}