component {

	property name="Factory" inject="ObjectFactory@cashbox";

	any function fetchByMerchantAccountID(required string id) {
		var obj = Factory.get("com.vindicia.client.Account");

		try {
			var resp = obj.fetchByMerchantAccountID(nullValue(),arguments.id);
		} catch (com.vindicia.client.VindiciaReturnException local.e) {
			return;
		}

		return resp;
	}

	any function create(required string merchantAccountID, string defaultCurrency="USD", required string email, string lang="en", boolean warnAutoBill=false, string company="", required string name) {
		var Account = Factory.get("com.vindicia.client.Account");
		Account.setMerchantAccountID(arguments.merchantAccountID);
		Account.setDefaultCurrency(arguments.defaultCurrency);
		Account.setEmailAddress(arguments.email);
		Account.setPreferredLanguage(arguments.lang);
		Account.setWarnBeforeAutoBilling(arguments.warnAutoBill);
		Account.setCompany(arguments.company);
		Account.setName(arguments.name);

		return Account.update(nullValue());
	}

}