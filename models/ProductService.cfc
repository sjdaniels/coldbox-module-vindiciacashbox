component {

	property name="Factory" inject="ObjectFactory@cashbox";

	function list(numeric offset=0, numeric pageSize=25) {
		var result = [];
		var Products = Factory.get("com.vindicia.client.Product");
		
		try {
			var items = Products.fetchAll( nullValue(), arguments.offset, arguments.pageSize );
		}
		catch (com.vindicia.client.VindiciaReturnException local.e) {
			if (local.e.ReturnCode == "404")
				return result; // no items
			else 
				rethrow;
		}


		for (var item in items) {
			result.append(item);
		}

		return result;
	}

}