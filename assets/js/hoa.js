// hoa.js
(function($) {

	var $wsvid = $('#vin_WebSession_vid');
	var $form = $wsvid.closest('form');

	var hoaURL = $wsvid.data('url');
	var returnURL = $wsvid.data('returnUrl');
	var sessionID = $wsvid.val();

	function onSubmit(e) {
		// use existing account is checked, just submit the form
		if ($('#useExisting_true:checked').length)
			return true;

		e.preventDefault();

		$.log("Posting to HOA url " + hoaURL);
		
		var fields = $form.serializeArray();
		fields.push({name:"vin_ajax", value:"1"});

		$.ajax({
			 method:"POST"
			,url:hoaURL
			,success:onSuccess
			,error:onError
			,data:fields
		});
	}

	function onError(response) {

		// update to new session ID (can't reuse sessions)
		sessionID = response.responseJSON.newWebSessionID;
		$wsvid.val( sessionID );

		$form.trigger('unsubmit');

		// reset account fields
		$('#vin_PaymentMethod_creditCard_account').val('');
		$('#vin_PaymentMethod_creditCard_expirationDate_month').val('');
		$('#vin_PaymentMethod_creditCard_expirationDate_year').val('');
		$('#vin_PaymentMethod_nameValues_cvn').val('');		

		$('#paymentMethodUpdateError #validationError').html( response.responseJSON.validationError );
		$('#paymentMethodUpdateError h2.modal-title').html( response.responseJSON.validationHeader );
		$('#paymentMethodUpdateError').modal();
	}

	function onSuccess(response) {
		$.log("HOA ajax post returned successfully from VWS. Finalizing WebSession...");
		$.ajax({
			 method: 'GET'
			,url: returnURL + "?session_id=" + sessionID
			,success:doSubmit
			,error: onError
		});
	}

	function doSubmit() {
		$(document).off('submit.hoa');
		$form.data('submitted',false);

		// clear sensitive fields
		$('#vin_PaymentMethod_creditCard_account').val('*************');
		$('#vin_PaymentMethod_creditCard_expirationDate_month').val('**');
		$('#vin_PaymentMethod_creditCard_expirationDate_year').val('****');
		$('#vin_PaymentMethod_nameValues_cvn').val('***');

		$form.submit();
	}

	// DATA API
	$(document)
		.off('submit.hoa')
		.on('submit.hoa', $form, onSubmit);

})(window.jQuery);