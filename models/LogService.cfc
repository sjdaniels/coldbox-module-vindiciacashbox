component {

	property name="wirebox" inject="wirebox";
	property name="logbox" inject="logbox";

	void function log( required string soapID, required string object, required string method, required numeric returnCode, required string returnString ) {
		if (wirebox.containsInstance("MongoDB")) {
			wirebox.getInstance("MongoDB").getCollection("vindiciacashbox_soap_log").save(["object":arguments.object, "method":arguments.method, "soapID":arguments.soapID, "returnCode":arguments.returnCode, "returnString":arguments.returnString]);
			return;
		}

		logbox.getLogger(this).info("CASHBOX #arguments.returnCode# SOAP ID: #arguments.soapID# #arguments.object#.#arguments.method#");
	}

}