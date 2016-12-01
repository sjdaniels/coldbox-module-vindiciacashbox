component {

	Transaction function populate(required any TransactionObj) {
		variables.TransactionObj = TransactionObj;
		return this;
	}

	function getMemento() {
		if (isnull(variables.TransactionObj))
			return;

		var txn = variables.TransactionObj;
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