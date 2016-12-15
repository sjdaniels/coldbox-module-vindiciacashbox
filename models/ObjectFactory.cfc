component {

	function get(required string class) {
		return createObject("java", arguments.class, [expandpath("/cashbox/lib/vindicia_NOAXIS.jar")]);
	}

	function getClassVersion() {
		if (isnull(variables.classVersion)) {
			var ClientConstants = get("com.vindicia.client.ClientConstants");
			variables.classVersion = "v#replace(ClientConstants.getVersion(),'.','_','all')#";
		}

		return variables.classVersion;
	}

}