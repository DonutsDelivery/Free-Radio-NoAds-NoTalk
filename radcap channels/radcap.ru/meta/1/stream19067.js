
function show_station_title() {
             $.ajax({
                 url: '//79.120.77.11:8000/status.xsl?mount=/hiphop',
                 cache: false,
                 success: function(data) {
                     $(data).find('tr').each(function() {
                         if ($(this).text().indexOf('Current Song:') + 1) {
                             $('#stream19067').html($(this).find('.streamdata').text());
                         }
                     })
                 }
             })
         }
		 $(document).ready(function() {
             show_station_title();
             setInterval('show_station_title()', 3000)
         });
