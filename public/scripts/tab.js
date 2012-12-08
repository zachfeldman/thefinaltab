(function($){
  $.fn.money_field = function(options) {
    var defaults = {
      width: null
    };
    var options = $.extend(defaults, options);
    
    return this.each(function() {
      obj = $(this);
      if(options.width)
        obj.css('width', options.width + 'px');
      	obj.css('height', '20px');
			obj.wrap("<div class='input-prepend'>");
      obj.before("<span class='add-on' style='height: 16px;'><span style='position: relative; top: -3px'>$</span></span>");
    });
  };
})(jQuery);



$(document).ready(function() {

	$.validator.addMethod("money", function (value, element) {
  return this.optional(element) || value.match(/^\$?\d+(\.(\d{2}))?$/);
}, "Please provide a valid dollar amount (up to 2 decimal places) and do not include a dollar sign.");

	var options = {
  	width: 80 // The css width to be applied to the textfield
	};

	$('#billAmount').money_field();	

	$( "#users").selectable({
		 filter:'tr',
        selected: function(event, ui){
            
						var s=$(this).find('.ui-selected td span').attr("class");
            console.log(s);
						$("#billUser").attr("value",s);
						
						$("#addBill").fadeIn('slow');
						
      }		
	});

	$("#newBill").submit(function(){
		event.preventDefault();
	});

	$("#billSubmit").click(function(){
		$("#newBill").validate({
			rules: {
          billAmount: {
						required: true,
						money: true
					},
					billName: "required"
      },  
      messages: {
      		billName: "Enter a name.",
					billAmount: "Enter an amount."
			},  
      submitHandler: function(form) {
				var billNameV = $("#billName").val();
				var billAmountV = $("#billAmount").val();
				var billTabV = $("#billTab").val();
				var billUserV = $("#billUser").val();
				$.post('/bills/new', {billName: billNameV, billAmount: billAmountV, billTab: billTabV, billUser: billUserV},  function(data) {
					if(data == "e"){
						$(".newBillMsg").html("Bill already added.");
					} else{
						$('#bills tbody tr:first').before(data);
					}	
				})
			}   
		});
	});

});
