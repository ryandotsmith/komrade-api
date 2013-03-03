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
	for (i in data) {
		$('#jobs-table > tbody').append(
			"<tr>" +
			"<td>" + data[i].count + "</td>" +
			"<td>" + data[i].last_created_at+ "</td>" +
			"<tr>"
		);

	}
}
