component {

	property name="Factory" inject="ObjectFactory@cashbox";

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

		return getWebSession().populate( ws );
	}

	public WebSession function getByVID(required string vid) {
		var ws = Factory.get("com.vindicia.client.WebSession");
		ws.setVID( arguments.vid );

		return getWebSession().populate( ws );
	}

}