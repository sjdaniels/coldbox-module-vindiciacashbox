component {

	function get(required string class) {
		return createObject("java", arguments.class, expandPath("/cashbox/lib/vindicia.jar"));
	}

}