Highcharts.theme = {
	credits: {enabled: false},
	chart: {
		borderWidth: 0,
		plotShadow: false,
		spacingTop: 20
	},
	plotOptions: {
		line: {
			marker: {enabled: false, symbol: "circle"},
			shadow: false
		}
	}
};

// Apply the theme
var highchartsOptions = Highcharts.setOptions(Highcharts.theme);
