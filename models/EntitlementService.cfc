component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="LogService" inject="LogService@cashbox";

	array function fetchDeltaSince(required date tsDelta, required numeric page, required numeric pageSize, date endTimestamp) {
		var result = [];
		var Entitlement = Factory.get("com.vindicia.client.Entitlement");
		var e;

		local.start = createobject("java","java.util.GregorianCalendar");
		local.start.setTime( arguments.tsDelta );

		if (!isnull(arguments.endTimestamp)) {
			local.end = createobject("java","java.util.GregorianCalendar");
			local.end.setTime( arguments.endTimestamp );
		}

		try {
			// java.lang.String srd, java.util.Calendar timestamp, int page, int pageSize, java.util.Calendar endTimestamp
			var response = Entitlement.fetchDeltaSince("", local.start, arguments.page, arguments.pageSize, local.end?:nullValue());
			for (local.item in (response?:[])) {
				if (!isnull(local.item.getEndTimestamp())) {
					local.dateEnd = local.item.getEndTimestamp().getTime();
				}
				
				local.update = { 
					 "isActive":local.item.getActive() 
					,"accountID":local.item.getAccount().getMerchantAccountID() 
					,"productID":local.item.getMerchantProductID() 
					,"autobillID":local.item.getMerchantAutobillID() 
					,"entitlementID":local.item.getMerchantEntitlementID() 
					,"dateStart":local.item.getStartTimestamp().getTime() 
					,"description":local.item.getDescription() 
				}

				if (!isnull(local.dateEnd) && local.dateEnd lt createdate(2098,1,1)) {
					local.update["dateEnd"] = local.dateEnd;
				}

				result.append( local.update );
			}

			return result;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "Entitlement", "fetchDeltaSince", e.returnCode, e.message );		
			rethrow;
		}
	}

	array function fetchByAccount(required string accountID) {
		var result = [];
		var Entitlement = Factory.get("com.vindicia.client.Entitlement");
		var e;

		var Account = Factory.get("com.vindicia.client.Account");
		Account.setMerchantAccountID( arguments.accountID );

		try {
			// java.lang.String srd, Account account, java.lang.Boolean showAll, java.lang.Boolean includeChildren
			var response = Entitlement.fetchByAccount("", Account, false, false);
			for (local.item in (response?:[])) {
				if (!isnull(local.item.getEndTimestamp())) {
					local.dateEnd = local.item.getEndTimestamp().getTime();
				}
				local.update = { 
					 "isActive":local.item.getActive() 
					,"accountID":local.item.getAccount().getMerchantAccountID() 
					,"productID":local.item.getMerchantProductID() 
					,"autobillID":local.item.getMerchantAutobillID() 
					,"entitlementID":local.item.getMerchantEntitlementID() 
					,"dateStart":local.item.getStartTimestamp().getTime() 
					,"description":local.item.getDescription() 
				}

				if (!isnull(local.dateEnd) && local.dateEnd lt createdate(2098,1,1)) {
					local.update["dateEnd"] = local.dateEnd;
				}

				result.append( local.update );
			}

			return result;
		}
		catch (com.vindicia.client.VindiciaReturnException e) {
			LogService.log( e.soapID, "Entitlement", "fetchByAccount", e.returnCode, e.message );		
			rethrow;
		}
	}
}