component {

	function get(required string class) {
		return createObject("java", arguments.class, [expandpath("/cashbox/lib/vindicia.jar"),expandpath("/cashbox/lib/vindicia_NOAXIS.jar")]);
	}

}