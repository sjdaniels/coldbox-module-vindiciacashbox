component {

	Refund function populate(required any RefundObj) {
		variables.RefundObj = RefundObj;
		return this;
	}

	function getMemento() {
		if (isnull(variables.RefundObj))
			return;

		var refund = variables.RefundObj;
		var result = {
			 "amount":javacast("numeric",refund.getAmount())
			,"currency":refund.getCurrency()
			,"vid":refund.getVID()
			,"id":refund.getMerchantRefundID()
			,"transactionID":refund.getTransaction().getMerchantTransactionID()
			,"memberID":refund.getTransaction().getAccount().getMerchantAccountID()
			,"dateCreated":refund.getTimestamp().getTime()
			,"status":refund.getStatus().getValue()
			,"strategy":refund.getRefundDistributionStrategy()
		}

		return result;
	}

}