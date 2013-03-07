//Scroll Detection
$(window).scroll(function(){
	if ($(window).scrollTop() == $(document).height() - $(window).height()){
		console.log('load more jobs');
	}
});

$(document).ready(function() {
	populateJobs($("#time-selector li.active a"));
	$("#time-selector a").click(function() {
		$("#time-selector li.active").removeClass('active');
		$(this).parent().addClass('active');
		populateJobs($(this));
		return false;
	});
});

function populateJobs(link) {
	//Clean up the old chart.
	$('#jobs-table').children().remove()
	var path = '/failed-jobs?resolution=' + link.data('resolution');
	console.log(path);
	$.getJSON(path, appendJobs);
}

function appendJobs(data) {
	if (data.length == 0) {
		$('#jobs-table').append(
			"<li>" +
			"<p collspan=4>No errors during this period.</p>" +
			"<li>"
		);
	} else {
		for (i in data) {
			$('#jobs-table').append(
				"<li class='clearfix'>" +
				"<div class='pull-left'><h4>" + _.escape(data[i].method) + "</h4>" +
				"Arguments:" +
				_.escape(data[i].args) + "</div>" +
				'<div class="date pull-right">' +
				data[i].last_created_at +
				"<div>" +
				'<button class="btn btn-danger"><i class="icon-trash icon-white"></i></button>' +
				'<button class="btn btn-success"><i class="icon-refresh icon-white"></i></button>' +
				'</div></div>' +
				"</li>"
			);
		}
	}
}
//				"<td>" + data[i].count + "</td>" +
