// A global chart.
var chart;
// Use this as a barrier for live updates.
// When you are in realtime mode, we want updates.
// However, when you are in hour or day mode you don't want updates.
var updateLock = false;

function appendOne(data) {
	var groups = _.groupBy(JSON.parse(data), 'action');
	for (var i in groups) {
		var s = chart.series[i];
		var metrics = groups[i];
		for (j in metrics) {
			var metric = metrics[j];
			s.addPoint([metric.time, metric.count],
				false, //redraw
				s.data.length > 60);
		}
	}
	chart.redraw();
}

function appendColl(data) {
	var metrics = _.groupBy(JSON.parse(data), 'action');
	for (var i in metrics) {
		var series = chart.series[i];
		series.setData(_.map(metrics[i], function(d) {
			return [d.time, d.count];
		}));
	}
	chart.redraw();
}

function newChartGetData(path) {
	$.ajax({url: path, success: appendColl});
	// If limit=X isn't in path, then we want realtime data.
	if (path == '/metrics') {
		setInterval(function(t) {
			if (updateLock) {
				clearInterval(t);
			} else {
				$.ajax({url: path, success: appendOne});
			}
		}, 1000);
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
}

$(document).ready(function() {
	initChart($("#chart-nav a.selected"));
	$("#chart-nav a").click(function() {
		if ($(this).attr('href') == '/metrics') {
			updateLock = false;
		} else {
			updateLock = true;
		}
		$("#chart-nav a.selected").removeClass('selected');
		$(this).addClass('selected');
		initChart($(this));
		return false;
	});
});
