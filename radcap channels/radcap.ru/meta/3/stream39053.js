
function show_station_title() {
             $.ajax({
                 url: '//79.111.14.76:8000/status.xsl?mount=/deathcore',
                 cache: false,
                 success: function(data) {
                     $(data).find('tr').each(function() {
                         if ($(this).text().indexOf('Current Song:') + 1) {
                             $('#stream39053').html($(this).find('.streamdata').text());
                         }
                     })
                 }
             })
         }
		 $(document).ready(function() {
             show_station_title();
             setInterval('show_station_title()', 3000)
         });
