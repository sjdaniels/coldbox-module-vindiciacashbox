component {

	property name="Factory" inject="ObjectFactory@cashbox";

	function list(numeric offset=0, numeric pageSize=25) {
		var Products = Factory.get("com.vindicia.client.Product");
		return Products.fetchAll( nullValue(), arguments.offset, arguments.pageSize );
	}

}