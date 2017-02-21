component {

	property name="wirebox" inject="wirebox";
	property name="logbox" inject="logbox";

	void function log( required string soapID, required string object, required string method, required numeric returnCode, required string returnString, struct details ) {
		arguments.returncode = javacast("numeric",arguments.returncode);

		if (wirebox.containsInstance("MongoDB")) {
			var doc = ["object":arguments.object, "method":arguments.method, "soapID":arguments.soapID, "returnCode":arguments.returnCode, "returnString":arguments.returnString];
			if (!isnull(arguments.details))
				doc["details"] = arguments.details;
				
			wirebox.getInstance("MongoDB").getCollection("cashbox_soap_log").save( doc );
			return;
		}

		logbox.getLogger(this).info("CASHBOX #arguments.returnCode# SOAP ID: #arguments.soapID# #arguments.object#.#arguments.method#");
	}

}