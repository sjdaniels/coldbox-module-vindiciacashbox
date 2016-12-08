component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="LogService" inject="LogService@cashbox";

	array function fetchDeltaSince(required date tsDelta, required numeric page, required numeric pageSize) {
		var result = [];
		var Entitlement = Factory.get("com.vindicia.client.Entitlement");
		var e;

		local.start = createobject("java","java.util.GregorianCalendar");
		local.start.setTime( arguments.tsDelta );

		try {
			// java.lang.String srd, java.util.Calendar timestamp, int page, int pageSize, java.util.Calendar endTimestamp
			var response = Entitlement.fetchDeltaSince("", local.start, arguments.page, arguments.pageSize, nullValue());
			for (local.item in (response?:[])) {
				result.append( { 
					 "isActive":local.item.getActive() 
					,"accountID":local.item.getAccount().getMerchantAccountID() 
					,"productID":local.item.getMerchantProductID() 
					,"autobillID":local.item.getMerchantAutobillID() 
					,"entitlementID":local.item.getMerchantEntitlementID() 
					,"dateStart":local.item.getStartTimestamp().getTime() 
					,"dateEnd":local.item.getEndTimestamp().getTime() 
					,"description":local.item.getDescription() 
				} );
			}

			return result;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "Entitlement", "fetchDeltaSince", e.returnCode, e.message );		
			rethrow;
		}
	}

}