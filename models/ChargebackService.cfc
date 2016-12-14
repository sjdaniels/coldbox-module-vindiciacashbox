component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="LogService" inject="LogService@cashbox";

	function getChargeback() provider="Chargeback@cashbox" {}

	array function fetchDeltaSince(required date tsDelta, required numeric page, required numeric pageSize) {
		var result = [];
		var Chargeback = Factory.get("com.vindicia.client.Chargeback");
		var e;

		local.start = createobject("java","java.util.GregorianCalendar");
		local.start.setTime( arguments.tsDelta );

		try {
			// java.lang.String srd, java.util.Calendar timestamp, java.util.Calendar endTimestamp, int page, int pageSize
			var response = Chargeback.fetchDeltaSince("", local.start, nullValue(), arguments.page, arguments.pageSize);
			for (local.item in (response?:[])) {
				result.append( getChargeback().populate(local.item) );
			}

			return result;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "Chargeback", "fetchDeltaSince", e.returnCode, e.message );		
			rethrow;
		}
	}

	public string function getStatusNotes(required string status) {
		var statuses = [
			  "Challenged":"Vindicia has submitted rebuttal documents to your payment processor to dispute this chargeback."
			, "CollectionsNew":"An inactive status."
			, "CollectionsWon":"An inactive status."
			, "CollectionsLost":"An inactive status."
			, "Duplicate":"A duplicate chargeback has either been manually entered or received by Vindicia from the payment processor. Another chargeback in the queue exists with exactly the same information but is not marked duplicate."
			, "Expired":"The related documents or transaction details you reported were received too late by Vindicia to dispute this chargeback."
			, "Incomplete":"Vindicia has received chargeback information from the payment processor but does not have the original transaction details from you."
			, "Legitimate":"A valid chargeback because the original transaction was truly fraudulent. Vindicia does not represent or dispute legitimate transactions."
			, "Lost":"Vindicia challenged this chargeback but lost the case."
			, "New":"The first chargeback received by Vindicia, which is in the process of deciding how to pursue on your behalf."
			, "NewSecondChargeback":"A second chargeback has been received against a transaction that was initially charged back, disputed, and won."
			, "Pass":"Even though all the documentation is available, Vindicia will not dispute this chargeback because of one or more of the following reasons: The chargeback is less than US$5. Not enough evidence exists for a dispute. Regulations do not allow Vindicia to respond. Vindicia does not recommend taking the dispute to arbitration."
			, "Retrieval":"An incoming retrieval or ticket request."
			, "Responded":"Vindicia has responded to the retrieval or ticket request."
			, "Represented":"As a result of Vindicia’s intervention, the chargeback was reversed in your favor. However, the customer or issuing bank is continuing the dispute by issuing a second chargeback. (This status is not in use.)"
			, "Won":"Vindicia challenged this chargeback, which has been reversed in your favor."			
		];

		return statuses[arguments.status] ?: "Unable to interpret status code #arguments.status#";
	}
}