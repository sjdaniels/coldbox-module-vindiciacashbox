component {

	property name="Factory" inject="ObjectFactory@cashbox";
	property name="LogService" inject="LogService@cashbox";

	function getWebSession() provider="WebSession@cashbox" {}; 

	public WebSession function initialize(required string method, required string returnURL, string errorURL, string ip=cgi.REMOTE_ADDR, struct privateFormValues={}, struct methodParamValues={}) {
		var i;
		var ws = Factory.get("com.vindicia.client.WebSession");
		
		ws.setMethod(arguments.method);
		ws.setReturnURL(arguments.returnURL);
		ws.setErrorURL(arguments.errorURL?:arguments.returnURL);
		ws.setIpAddress(arguments.ip);

		local.pfv = [];
		for (i in arguments.privateFormValues) {
			local.nvp = Factory.get("com.vindicia.client.NameValuePair");
			local.nvp.setName(i);
			local.nvp.setValue(arguments.privateFormValues[i]);
			local.pfv.append( local.nvp );
		}

		local.mpv = [];
		for (i in arguments.methodParamValues) {
			local.nvp = Factory.get("com.vindicia.client.NameValuePair");
			local.nvp.setName(i);
			local.nvp.setValue(arguments.methodParamValues[i]);
			local.mpv.append( local.nvp );
		}

		ws.setPrivateFormValues( local.pfv );
		ws.setMethodParamValues( local.mpv );

		local.result = ws.initialize(nullValue());

		LogService.log( local.result.getSoapId(), "WebSession", "initialize" );

		return getWebSession().populate( ws );
	}

	public WebSession function getByVID(required string vid) {
		var ws = Factory.get("com.vindicia.client.WebSession");
		ws.setVID( arguments.vid );

		return getWebSession().populate( ws );
	}

	public WebSession function finalize(required string sessionID) {
		var ws = getByVID(arguments.sessionID);
		var wso = ws.getWSO();
    	local.result = wso.finalize_via_SOAP(nullValue());

		LogService.log( local.result.getSoapId(), "WebSession", "finalize" );
    	return ws;
	}

}