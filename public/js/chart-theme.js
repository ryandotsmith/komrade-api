Highcharts.theme = {
	credits: {enabled: false},
	chart: {
		backgroundColor: '#ECECE7',
		plotBackgroundColor: '#ECECE7',
		borderWidth: 0,
		plotShadow: false,
		spacingTop: 20,
		tooltip: {
			xDateFormat: '%Y-%m-%d %H:%M:%S',
			shared: true
		}
	},
	plotOptions: {
		line: {marker: {enabled: false}}
	}
};

// Apply the theme
var highchartsOptions = Highcharts.setOptions(Highcharts.theme);
