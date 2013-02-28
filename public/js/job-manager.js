$(document).ready(function() {
  updateFailedJobRows(0)
  setInterval('updateFailedJobRows(new Date().getTime() - 3000)', 3000)
});

function updateFailedJobRows(timestamp) {
  console.log('at=update-failed-job-rows path="/failed_jobs"')
  $.getJSON('/failed_jobs/' + timestamp, function(d) {
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
