component {

	property name="settings" inject="coldbox:setting:vindicia";

	function get(required string class) {
		if (settings.debug ?: false)
			return createObject("java", arguments.class, [expandpath("/cashbox/lib/vindicia_DEBUG.jar")]);
		
		return createObject("java", arguments.class, [expandpath("/cashbox/lib/vindicia.jar")]);
	}

	function getClassVersion() {
		if (isnull(variables.classVersion)) {
			var ClientConstants = get("com.vindicia.client.ClientConstants");
			variables.classVersion = "v#replace(ClientConstants.getVersion(),'.','_','all')#";
		}

		return variables.classVersion;
	}

}