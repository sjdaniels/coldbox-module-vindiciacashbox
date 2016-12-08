component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="settings" inject="coldbox:setting:vindicia";
	property name="LogService" inject="LogService@cashbox";

	struct function update(required string id, required string ip, required string accountID, required string paymentmethodID, required string productID, string affiliateID="", string currency="USD", string billingStatementID, numeric minChargebackProbability=100) {
		var ClientConstants = Factory.get("com.vindicia.client.ClientConstants");
		var classVersion = "v#replace(ClientConstants.getVersion(),'.','_','all')#";
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

	any function getNextBillingDate( required string autobillID ) {
		local.autobill = Factory.get("com.vindicia.client.AutoBill").fetchByMerchantAutobillID("", arguments.autobillID);
		if (isnull(local.autobill))
			return;

		local.nextbilling = local.autobill.getNextBilling();
		if (isnull(local.nextbilling))
			return;

		local.result = local.nextbilling.getTimestamp().getTime();

		return local.result;
	}
}