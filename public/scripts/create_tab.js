$(document).ready(function() {

 	function isValidEmailAddress(emailAddress) {
	    var pattern = new RegExp(/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i);
		    return pattern.test(emailAddress);
	};
	
	$(".addTabUser").click(function(){
		var email = $("input[name='tabUsers']").val();
		if(isValidEmailAddress(email)){
			$.post('/tabs/create/'+email, function(data) {
				if(data == "sent"){
					$('.result').html("Invitation sent!");
				} else if(data == "alreadySent"){
					$('.result').html("Invitation already sent.");
				} else{
					$('#userTable tr:last').after(data);
					var id = $( data ).filter( '#userId' ).attr("class");
					var oldId = $('#allUserIds').val();
					$('#allUserIds').val(oldId + ", " + id);
				}
			});
		}else{
			$('.result').html("Invalid e-mail address.");
		}
	});


	$("#tabForm").validate({
		  rules: {
					tabName: "required"
			},
			messages: {
					tabName: "Please enter a name for your tab."
			},
			submitHandler: function(form) {
					form.submit();
			}	

	});
	/*
	$(".addTab").click(function(){
		$('.tabNameMsg').html("");
		$('.tabNotesMsg').html("");
		
		var tabName = $("input[name='tabName']").val();
		if(tabName == ""){
			$('.tabNameMsg').html("Tab name cannot be empty.");
		} else{
			var tabNotes = $("textarea[name='tabNotes']").val();
			if(tabNotes == ""){
				$('.tabNotesMsg').html("Tab notes cannot be empty.");
			} else{
				var userIDs = [];
				if($("#allUserIds").length != 0){
					alert('hello');
				} 
			}
		}
	});
	*/
});
