component {

	property name="settings" inject="coldbox:setting:vindicia";

	function getWSDL() {
		return settings.host & "/Account.wsdl";
	}

	function fetchByMerchantAccountID(required string id) {
		
	}

}