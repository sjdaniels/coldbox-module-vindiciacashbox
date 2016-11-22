component {

	property name="wirebox" inject="wirebox";
	property name="logbox" inject="logbox";

	void function log( required string soapID, required string object, required string method ) {
		if (wirebox.containsInstance("MongoDB")) {
			wirebox.getInstance("MongoDB").getCollection("vindiciacashbox_soap_log").save(["object":arguments.object, "method":arguments.method, "soapID":arguments.soapID]);
			return;
		}

		logbox.getLogger(this).info("CASHBOX SOAP ID: #arguments.soapID# #arguments.object#.#arguments.method#");
	}

}