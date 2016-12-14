component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="LogService" inject="LogService@cashbox";

	function getRefund() provider="Refund@cashbox" {}

	array function fetchDeltaSince(required date tsDelta) {
		var result = [];
		var Refund = Factory.get("com.vindicia.client.Refund");
		var e;

		local.start = createobject("java","java.util.GregorianCalendar");
		local.start.setTime( arguments.tsDelta );

		try {
			// java.lang.String srd, java.util.Calendar timestamp, java.util.Calendar endTimestamp, PaymentMethod
			var response = Refund.fetchDeltaSince("", local.start, nullValue(), nullValue());
			for (local.item in (response?:[])) {
				result.append( getRefund().populate(local.item) );
			}

			return result;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "Refund", "fetchDeltaSince", e.returnCode, e.message );		
			rethrow;
		}
	}

}