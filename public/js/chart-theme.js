Highcharts.theme = {
	credits: {enabled: false},
	chart: {
		backgroundColor: '#ECECE7',
		plotBackgroundColor: '#ECECE7',
		borderWidth: 0,
		plotShadow: false,
		spacingTop: 20
	},
	plotOptions: {
		line: {marker: {enabled: false, symbol: "circle"}}
	}
};

// Apply the theme
var highchartsOptions = Highcharts.setOptions(Highcharts.theme);
