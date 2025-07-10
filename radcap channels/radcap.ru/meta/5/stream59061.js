
function show_station_title() {
             $.ajax({
                 url: '//213.141.131.10:8000/status.xsl?mount=/medievalfolk',
                 cache: false,
                 success: function(data) {
                     $(data).find('tr').each(function() {
                         if ($(this).text().indexOf('Current Song:') + 1) {
                             $('#stream59061').html($(this).find('.streamdata').text());
                         }
                     })
                 }
             })
         }
		 $(document).ready(function() {
             show_station_title();
             setInterval('show_station_title()', 3000)
         });
