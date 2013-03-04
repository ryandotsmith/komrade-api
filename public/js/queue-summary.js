$(document).ready(function() {
	updateSummary();
});

function updateSummary() {
	var an = _.template("<span>App: <strong><%=name%></strong></span>");
	var ql = _.template("<span>QueueLength: <strong><%=length%></strong></span>");

	$.getJSON("/summary", function(data) {
		$("#queue-summary").children().remove();
		$("#queue-summary").
			append(an({name: data.app_name})).
			append(ql({length: data.queue_length}));
	});
	setTimeout(updateSummary, 1000);
}
