component {

	WebSession function populate(required WebSessionObj) {
		variables.WebSessionObj = arguments.WebSessionObj;
		return this;
	}

	function getWS() {
		return variables.WebSessionObj;
	}
}