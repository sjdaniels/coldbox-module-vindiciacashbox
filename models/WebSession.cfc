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
		result.code = wso.getApiReturn().getReturnCode().toString();
		result.message = wso.getApiReturn().getReturnString();

		if (wso.getApiReturn().getReturnCode().toString()=="200") {
			result.success = true;
		} else {
			result.success = false;
		}
		return result;
	}

	public struct function getAutobill() {
		local.update = getWSO().getApiReturnValues().getAutoBillUpdate();
		if (isnull(local.update))
			return {};

		// persist the initial transaction
		variables.transaction = local.update.getInitialTransaction();

		// persist the fraud score
		variables.score = local.update.getScore();

		local.autobill = local.update.getAutobill();

		if (isnull(local.autobill))
			return {};

		// persist the payment method
		variables.paymentmethod = local.autobill.getPaymentMethod();

		return [ "last":local.autobill.getItems(0).getProduct().getMerchantProductID(), "next":local.autobill.getItems(0).getProduct().getMerchantProductID(), "dateNext":local.autobill.getNextBilling().getTimestamp().getTime(), "currency":local.autobill.getCurrency() ];
	}

	public any function getScore() {
		if (isnull(variables.score))
			return;

		return variables.score;
	}

	public struct function getPaymentMethod() {
		if (isnull(variables.paymentmethod))
			throw("No payment method available.","VindicaCashboxModuleWebsessionException");

		var pm = variables.paymentmethod;
		var result = { "type":pm.getType().getValue() }

		if (result.type == "CreditCard") {
			local.creditcard = pm.getCreditCard();
			result["accountmask"] = local.creditcard.getAccount();
			result["bin"] = local.creditcard.getBin();
			result["lastdigits"] = local.creditcard.getLastDigits();
			result["dateExpires"] = createDate( left(local.creditcard.getExpirationDate(),4), right(local.creditcard.getExpirationDate(),2), daysInMonth(createDate(left(local.creditcard.getExpirationDate(),4), right(local.creditcard.getExpirationDate(),2),1)) );
			result["cardholder"] = pm.getAccountHolderName();
			result["accountLength"] = local.creditcard.getAccountLength();
			result["vid"] = pm.getVID();
			result["id"] = pm.getMerchantPaymentMethodID();
		}

		// process other types

		return result;
	}

	public any function getTransaction() {
		if (isnull(variables.transaction))
			return;

		var txn = variables.transaction;
		var items = [];
		for (var item in txn.getTransactionItems()) {
			if (item.sku != "Total Tax")
				items.append(item.getSku());
		}

		var statuslog = [];
		for (var statusentry in txn.getStatusLog()) {
			statuslog.append(statusentry.getStatus().getValue());
		}

		var result = {
			 "memberID":txn.getAccount().getMerchantAccountID()
			,"amount":javacast("numeric",txn.getAmount())
			// ,"amountOriginal":javacast("numeric",txn.getOriginalAmount())
			,"billingPlanCycle":txn.getBillingPlanCycle()
			,"currency":txn.getCurrency()
			,"paymentMethodID":txn.getSourcePaymentMethod().getMerchantPaymentMethodID()
			,"affiliateID":txn.getMerchantAffiliateID()
			,"vid":txn.getVID()
			,"id":txn.getMerchantTransactionID()
			,"ip":txn.getSourceIP()
			,"items":items
			,"statuslog":statuslog
			,"dateCreated":txn.getTimestamp().getTime()
		}

		return result;
	}
}