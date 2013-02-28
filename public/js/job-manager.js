$(document).ready(function() {
  setInterval('updateFailedJobRows()', 3000)
});

function updateFailedJobRows() {
  console.log('at=update-failed-job-rows path="/failed_jobs"')
  $.getJSON('/failed_jobs/' + new Date().getTime(), function(d) {
    $.each(d, function(i, data) {
      $('table > tbody').append(
         "<tr>" +
            "<td>" + data.created_at + "</td>" +
            "<td>" + data.method + "</td>" +
            "<td>" + data.args + "</td>" +
            "<td>" + data.error + "</td>" +
            "<td>" + data.message + "</td>" +
          "<tr>");
    });
  });
}
