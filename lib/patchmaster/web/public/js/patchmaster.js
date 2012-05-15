list = function(id, vals) {
  var lis = '';
  $.each(vals, function(i, val) {
    lis += "<li>" + val + "</li>";
  });
  $('#' + id).html(lis);
}

kp = function(action) {
  $.getJSON(action, function(data) {
    list('song-lists', data['lists']);
    list('songs', data['songs']);
    list('triggers', data['triggers']);

    // TODO rest of the data

    if (data['message'])
      $('#message').html(data['message']);
  });
}

var d = $(document);
d.bind('keydown', 'j', function() { kp('next_patch'); });
d.bind('keydown', 'down', function() { kp('next_patch'); });
d.bind('keydown', 'k', function() { kp('prev_patch'); });
d.bind('keydown', 'up', function() { kp('prev_patch'); });
d.bind('keydown', 'n', function() { kp('next_song'); });
d.bind('keydown', 'left', function() { kp('next_song'); });
d.bind('keydown', 'p', function() { kp('prev_song'); });
d.bind('keydown', 'right', function() { kp('prev_song'); });
d.bind('keydown', 'esc', function() { kp('panic'); });

kp('status');
