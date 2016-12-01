<cfscript>
	param name="args.sessionID";
</cfscript>
<cfoutput>
	<!--- CashBox HOA request fields --->
	<input type="hidden" id="vin_WebSession_vid" name="vin_WebSession_vid" value="#args.sessionID#" data-url="#getSetting('vindicia').hoaURL#" data-return-url="#prc.returnURL#">
	<!--- Error Handling Modal - requires Bootstrap, will fall back to alerts() --->
	<div class="modal fade" id="paymentMethodUpdateError">
		<div class="modal-dialog">
			<div class="modal-content">
				<div class="modal-header">
					<button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
					<h2 class="modal-title">&nbsp;</h2>					
				</div>
				<div class="modal-body">
					<p id="validationError"></p>
				</div>
			</div>	
		</div>
	</div>
	<!--- Add the Javacsript --->
	#html.addJSContent( fileread( expandpath(getDirectoryFromPath(getCurrentTemplatePath()) & "../assets/js/hoa.js") ) )#
</cfoutput>