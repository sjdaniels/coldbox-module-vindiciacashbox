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
			if (item.sku != "Total Tax") {
				items.append({"productID":item.getSku(), "subtotal":javacast("numeric",item.getSubtotal()?:0), "price":javacast("numeric",item.getPrice()?:0), "quantity":javacast("numeric",item.getQuantity()?:0)});
			}
		}

		var statuslog = [];
		for (var statusentry in (txn.getStatusLog()?:[])) {
			statuslog.append(statusentry.getStatus().getValue());
		}

		var result = {
			 "memberID":!isnull(txn.getAccount()) ? txn.getAccount().getMerchantAccountID() : "noaccountid"
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