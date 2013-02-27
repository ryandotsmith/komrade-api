function hideErrors() {
	var found = false;

	var m = $("#errors-minute");
	if (m.children().length == 0) {
		m.parent().hide();
	} else {
		found = true;
	}
	var h = $("#errors-hour");
	if ((h.children().length == 0) || found) {
		h.parent().hide();
	} else {
		found = true;
	}

	var d = $("#errors-day");
	if ((d.children().length == 0) || found) {
		d.parent().hide();
	}
}

$(document).ready(function() {
	hideErrors();

	$(".error-link").click(function() {
		var t = $(this).attr('rel');
		$(".errors-detail").hide();
		$("#"+t).parent().show();
	});
})
