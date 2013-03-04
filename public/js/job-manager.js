//Scroll Detection
$(window).scroll(function(){
	if ($(window).scrollTop() == $(document).height() - $(window).height()){
		console.log('load more jobs');
	}
});

$(document).ready(function() {
	populateJobs($("#job-manager-nav a.selected"));
	$("#job-manager-nav a").click(function() {
		$("#job-manager-nav a.selected").removeClass('selected');
		$(this).addClass('selected');
		populateJobs($(this));
		return false;
	});
});

function populateJobs(link) {
	//Clean up the old chart.
	$('#jobs-table > tbody').children().remove()
	$.getJSON(link.attr('href'), appendJobs);
}

function appendJobs(data) {
	if (data.length == 0) {
		$('#jobs-table > tbody').append(
			"<tr>" +
			"<td collspan=4>No errors during this period.</td>" +
			"<tr>"
		);
	} else {
		for (i in data) {
			$('#jobs-table > tbody').append(
				"<tr>" +
				"<td>" + data[i].count + "</td>" +
				"<td>" + data[i].last_created_at+ "</td>" +
				"<td>" + _.escape(data[i].method) + "</td>" +
				"<td>" + _.escape(data[i].args) + "</td>" +
				"<tr>"
			);
		}
	}
}
