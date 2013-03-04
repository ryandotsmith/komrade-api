$(document).ready(function() {
	setInterval(updateSummary, 1000);
});

function updateSummary() {
	var an = _.template("<span>App: <%=name%></span>");
	var ql = _.template("<span>Queue Length: <%=length%></span>");

	$.getJSON("/summary", function(data) {
		$("#queue-summary").children().remove();
		$("#queue-summary").
			append(an({name: data.app_name})).
			append(ql({length: data.queue_length}));
	});
}
