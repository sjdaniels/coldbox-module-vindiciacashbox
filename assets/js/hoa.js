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
		var fields = {
			  vin_PaymentMethod_accountHolderName: $('#cardholder').val()
			, vin_PaymentMethod_billingAddress_postalCode: $('#postalCode').val()
			, vin_PaymentMethod_billingAddress_country: $('#country').val()
			, vin_PaymentMethod_creditCard_account: $('#accountNum').val()
			, vin_PaymentMethod_creditCard_expirationDate_month: $('#ccExpM').val()
			, vin_PaymentMethod_creditCard_expirationDate_year: $('#ccExpY').val()
			, vin_PaymentMethod_nameValues_cvn: $('#cvn').val()
			, vin_ajax: 1
			, vin_WebSession_VID: sessionID			
		}

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
		$('#accountNum').val('*************');
		$('#ccExpM').val('**');
		$('#ccExpY').val('****');
		$('#cvn').val('***');

		$form.submit();
	}

	// DATA API
	$(document)
		.off('submit.hoa')
		.on('submit.hoa', $form, onSubmit);

})(window.jQuery);