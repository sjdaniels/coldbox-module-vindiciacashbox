component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="settings" inject="coldbox:setting:vindicia";

	any function fetchByMerchantAccountID(required string id) {
		var obj = Factory.get("com.vindicia.client.Account");

		try {
			var resp = obj.fetchByMerchantAccountID(nullValue(),arguments.id);
		} catch (com.vindicia.client.VindiciaReturnException local.e) {
			return;
		}

		return resp;
	}

	any function update(required string merchantAccountID, string defaultCurrency="USD", required string email, string lang="en", boolean warnAutoBill=false, string company="", required string name, string zip="", string country="", string shipName="") {
		var classVersion = Factory.getClassVersion();
		var Account = Factory.get("com.vindicia.client.Account");

		if (settings.isdev) {
			local.uid = listfirst(arguments.merchantAccountID,"-");
			arguments.name = " #local.uid# Cashbox Scrubbed";
			arguments.email = "#local.uid#@scrubbed.com";
			if (arguments.company.len())
				arguments.company = "Company Scrubbed";
			if (arguments.shipName.len())
				arguments.shipName = "Shipping Name Scrubbed";
		}

		Account.setMerchantAccountID(arguments.merchantAccountID);
		Account.setDefaultCurrency(arguments.defaultCurrency);
		Account.setEmailAddress(arguments.email);
		Account.setPreferredLanguage(arguments.lang);
		Account.setWarnBeforeAutoBilling(arguments.warnAutoBill);
		Account.setCompany(arguments.company);
		Account.setName(arguments.name);

		var Address = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.Address");
		Address.setCountry(arguments.country);
		Address.setPostalCode(arguments.zip);
		Address.setName(arguments.shipName);

		Account.setShippingAddress(Address);

		return Account.update(nullValue());
	}

	any function setPaymentMethodInactive(required string paymentMethodID) {
		var PaymentMethod = Factory.get("com.vindicia.client.PaymentMethod").fetchByMerchantPaymentMethodID('', arguments.paymentMethodID);
		PaymentMethod.setActive(false);
		// java.lang.String srd, boolean validate, int minChargebackProbability, boolean replaceOnAllAutoBills, java.lang.String sourceIp, java.lang.Boolean replaceOnAllChildAutoBills, java.lang.Boolean ignoreAvsPolicy, java.lang.Boolean ignoreCvnPolicy
		return PaymentMethod.update('', false, 100, false, nullValue(), false, true, true);
	}

	// ONLY USED FOR CREATING TEST CARDS IN PRODTEST!
	any function updatePaymentMethod(required string merchantAccountID, required string paymentMethodID, required string accountNum, required date dateExpires) {
		var classVersion = Factory.getClassVersion();
		var Account = Factory.get("com.vindicia.client.Account").fetchByMerchantAccountId('',arguments.merchantAccountID);
		var PaymentMethod = Factory.get("com.vindicia.client.PaymentMethod");
		var cc = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.CreditCard");
		var PaymentMethodType = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.PaymentMethodType").fromString("CreditCard");
		var PaymentUpdateBehavior = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.PaymentUpdateBehavior").fromString("Update");

		Account.setMerchantAccountID(arguments.merchantAccountID);

		PaymentMethod.setBillingAddress( Account.getShippingAddress() );
		PaymentMethod.setMerchantPaymentMethodID( arguments.paymentMethodID );

		cc.setAccount(arguments.accountNum);
		cc.setExpirationDate(dateformat(arguments.dateExpires,"YYYYMM"));
		PaymentMethod.setType(PaymentMethodType);
		PaymentMethod.setCreditCard(cc);

		// java.lang.String srd, PaymentMethod paymentMethod, boolean replaceOnAllAutoBills, PaymentUpdateBehavior updateBehavior, java.lang.Boolean ignoreAvsPolicy, java.lang.Boolean ignoreCvnPolicy
		return Account.updatePaymentMethod('', PaymentMethod, true, PaymentUpdateBehavior, true, true);
	}

	any function grantCredit(required string merchantAccountID, required numeric amount, string note="") {
		var classVersion = Factory.getClassVersion();
		var Account = Factory.get("com.vindicia.client.Account");
		
		Account.setMerchantAccountID(arguments.merchantAccountID);
		
		var Credit = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.Credit");
		var CurrencyAmount = Factory.get("com.vindicia.soap.#classVersion#.Vindicia.CurrencyAmount");

		CurrencyAmount.setAmount( javacast("java.math.BigDecimal", abs(arguments.amount)) );
		CurrencyAmount.setDescription( arguments.note );
		Credit.setCurrencyAmounts([ CurrencyAmount ]);

		// java.lang.String srd, Credit credit, java.lang.String note
		return Account.grantCredit('', Credit, arguments.note);
	}
}