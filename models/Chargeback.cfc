component {

	Chargeback function populate(required any ChargebackObj) {
		variables.ChargebackObj = ChargebackObj;
		return this;
	}

	function getMemento() {
		if (isnull(variables.ChargebackObj))
			return;

		var chargeback = variables.ChargebackObj;
		var result = {
			 "amount":javacast("numeric",chargeback.getAmount())
			,"currency":chargeback.getCurrency()
			,"vid":chargeback.getVID()
			,"id":chargeback.getVID()
			,"transactionID":chargeback.getMerchantTransactionID()
			,"dateCreated":chargeback.getProcessorReceivedTimestamp().getTime()
			,"status":chargeback.getStatus().getValue()
		}

		return result;
	}
}