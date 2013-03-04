// A global chart.
var chart;
// Use this as a barrier for live updates.
// When you are in realtime mode, we want updates.
// However, when you are in hour or day mode you don't want updates.
var updateLock = false;

function appendOne(data, status, request) {
	var groups = _.groupBy(JSON.parse(data), 'action');
	var timeStamp = Date.parse(request.getResponseHeader("X_SERVER_TIME"));
	if (groups.length == 0) {
		timeStamp = Date.parse(groups[0][0].time);
	}
	for (var i in chart.series) {
		var s = chart.series[i];
		var metrics = groups[i];
		if (_.isUndefined(metrics)) {
			s.addPoint([timeStamp, 0], false, s.data.length > 12);
		} else {
			var metric = metrics[0];
			s.addPoint([Date.parse(metric.time), metric.count],
				false, //redraw
				s.data.length > 12);
		}
	}
	chart.redraw();
}

function appendColl(data) {
	var metrics = _.groupBy(JSON.parse(data), 'action');
	for (var i in metrics) {
		var series = chart.series[i];
		series.setData(_.map(metrics[i], function(d) {
			return [Date.parse(d.time), d.count];
		}));
	}
	chart.redraw();
}

function newChartGetData(path) {
	// If limit=X isn't in path, then we want realtime data.
	if (path == '/metrics') {
		$.ajax({url: path, success: appendOne});
		setInterval(function(t) {
			if (updateLock) {
				clearInterval(t);
			} else {
				$.ajax({url: path, success: appendOne});
			}
		}, 5000);
	} else {
		$.ajax({url: path, success: appendColl});
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
		tooltip: {
			xDateFormat: '%Y-%m-%d %H:%M:%S',
			shared: true
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
