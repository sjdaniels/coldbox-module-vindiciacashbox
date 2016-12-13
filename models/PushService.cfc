component {

	property name="settings" inject="coldbox:setting:vindicia";

	public struct function authenticate(required string signature, required string rawbody, string secret=settings.callback_key) {
		var mac 		= createObject("java","javax.crypto.Mac").getInstance("HmacSHA256");
		var keyspec 	= createobject("java","javax.crypto.spec.SecretKeySpec").init(secret.getBytes(), "HmacSHA256");
		var Base64 		= createobject("java","org.apache.commons.codec.binary.Base64");
		
		mac.init( keyspec );

		var sig = Base64.encodeBase64String(mac.doFinal(arguments.rawbody.getBytes()));
		var result = {
			 "isAuthenticated":(sig == arguments.signature)
			,"signature":arguments.signature
			,"hash":sig
		}
		
		return result;
	}

}