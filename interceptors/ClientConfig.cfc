component output="false" extends="coldbox.system.Interceptor"  {

	public function configure(){
		return this;
	}
	
	public void function afterConfigurationLoad(event,interceptData){
		var settings = getSetting("vindicia");
		var ClientConstants = getInstance("ObjectFactory@cashbox").get("com.vindicia.client.ClientConstants");
		ClientConstants.DEFAULT_VINDICIA_SERVICE_URL = settings.host;
		ClientConstants.SOAP_LOGIN = settings.username;
		ClientConstants.SOAP_PASSWORD = settings.password;
	}
}