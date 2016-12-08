component {

	WebSession function populate(required WebSessionObj) {
		variables.WebSessionObj = arguments.WebSessionObj;
		return this;
	}

	function getWSO() {
		return variables.WebSessionObj;
	}

	public string function getVID() {
		return getWSO().getVID();
	}

	public struct function getResult() {
		var wso = getWSO();
		var result = {};
		result["code"] = wso.getApiReturn().getReturnCode().toString();
		result["message"] = wso.getApiReturn().getReturnString();

		if (wso.getApiReturn().getReturnCode().toString()=="200") {
			result["success"] = true;
		} else {
			result["success"] = false;
		}
		return result;
	}

	public struct function getPaymentMethod() {
		if (isnull(variables.paymentmethod))
			throw("No payment method available.","VindicaCashboxModuleWebsessionException");

		var pm = variables.paymentmethod;
		var result = { "type":pm.getType().getValue() }

		if (result.type == "CreditCard") {
			local.creditcard = pm.getCreditCard();
			local.billingAddress = pm.getBillingAddress();
			result["accountmask"] = local.creditcard.getAccount();
			result["bin"] = local.creditcard.getBin();
			result["lastdigits"] = local.creditcard.getLastDigits();
			result["dateExpires"] = createDate( left(local.creditcard.getExpirationDate(),4), right(local.creditcard.getExpirationDate(),2), daysInMonth(createDate(left(local.creditcard.getExpirationDate(),4), right(local.creditcard.getExpirationDate(),2),1)) );
			result["cardholder"] = pm.getAccountHolderName();
			result["accountLength"] = local.creditcard.getAccountLength();
			result["vid"] = pm.getVID();
			result["id"] = pm.getMerchantPaymentMethodID();
			
			if (!isnull(local.billingAddress)) {
				result["country"] = local.billingAddress.getCountry();
				result["zip"] = local.billingAddress.getPostalCode();
			}
		}

		// process other types

		return result;
	}

	public boolean function getAccountUpdatePaymentMethod() {
		local.update = getWSO().getApiReturnValues().getAccountUpdatePaymentMethod();
		if (isnull(local.update) || isnull(local.update.getAccount()))
			return false;

		// persist the payment method
		variables.paymentmethod = local.update.getAccount().getPaymentMethods(0);

		return true;
	}
}