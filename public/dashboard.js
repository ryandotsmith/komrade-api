// A global chart.
var chart;
// Use this as a barrier for live updates.
// When you are in realtime mode, we want updates.
// However, when you are in hour or day mode you don't want updates.
var updateLock = false;

function appendData(data) {
	var groups = JSON.parse(data);
	// in  out error lost
	//[[x,y], [x,y], [x,y], [x,y]]
	for (var i in groups) {
		var metric = groups[i];
		var s = chart.series[metric.action];
		var shift = s.data.length > 60;
		s.addPoint([metric.time, metric.count], true, shift);
	}
}

function getData(path) {
	console.log('at=get-data path='+path);
	$.ajax({
		url: path,
		cache: false,
		beforeSend: function() {
			$("#chart-spinner").show();
		},
		success: function() {
			$("#chart-spinner").hide();
			appendData
		}
	});
}

function newChartGetData(path) {
	getData(path);
	if (path == '/metrics') {
		setInterval(function(t) {
			if (updateLock) {
				clearInterval(t);
			} else {
				getData(path);
			}
		}, 3000);
	}
}

function initChart(link) {
	//Clean up the old chart.
	var path = link.attr('href');
	var container = link.parent().parent();
	container.find('.chart').remove()
	var elt = $('<div class="chart">').appendTo(container);
	chart = new Highcharts.Chart({
		chart: {
			renderTo: elt[0],
			type: 'line',
			events: {load: function(){newChartGetData(path)}}
		},
		title: {text: null},
		xAxis: {type: 'datetime',labels: {enabled: false}},
		yAxis: {min: 0, title: {text: null}},
		series: [
			{name: 'enqueue', data: []},
			{name: 'dequeue', data: []},
			{name: 'delete', data: []},
			{name: 'error', data: [], color: 'salmon', marker: {radius: 4, symbol: 'triangle'}}
		]
	});
	// Hide dequeue & delete by default.
	// Enqueue and errors are more important?
	chart.series[2].hide();
	chart.series[1].hide();
}

$(document).ready(function() {
	initChart($(".chart-nav a.selected"));
	$(".chart-nav a").click(function() {
		if ($(this).attr('data-realtime') == 'true') {
			updateLock = false;
		} else {
			updateLock = true;
		}

		$(".chart-nav a.selected").removeClass('selected');
		$(this).addClass('selected');
		initChart($(this));
		return false;
	});
});
