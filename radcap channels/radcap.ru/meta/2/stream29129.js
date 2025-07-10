
function show_station_title() {
             $.ajax({
                 url: '//79.120.39.202:8000/status.xsl?mount=/electroclash',
                 cache: false,
                 success: function(data) {
                     $(data).find('tr').each(function() {
                         if ($(this).text().indexOf('Current Song:') + 1) {
                             $('#stream29129').html($(this).find('.streamdata').text());
                         }
                     })
                 }
             })
         }
		 $(document).ready(function() {
             show_station_title();
             setInterval('show_station_title()', 3000)
         });
