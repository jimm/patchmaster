var CONN_HEADERS = "<tr>\
  <th>Input</th>\
  <th>Chan</th>\
  <th>Output</th>\
  <th>Chan</th>\
  <th>Prog</th>\
  <th>Zone</th>\
  <th>Xpose</th>\
  <th>Filter</th>\
</tr>";
var CONN_KEYS = ['input', 'input_chan', 'output', 'output_chan', 'pc', 'zone', 'xpose', 'filter'];
var color_schemes = ['default', 'green', 'amber', 'blue'];
var color_scheme_index = 0;

list = function(id, vals, highlighted_value) {
  var lis = '';
  $.each(vals, function(i, val) { 
    var li_class = val == highlighted_value ? ' class="selected"' : '';
    lis += "<li" + li_class + ">" + val + "</li>";
  });
  $('#' + id).html(lis);
}

connection_rows = function(connections) {
  var rows = CONN_HEADERS;
  $.each(connections, function(i, conn) {
    var vals = CONN_KEYS.map(function(k) { return conn[k]; });
    rows += "<tr><td>" + vals.join("</td><td>") + "</td></tr>";
  });
  $('#patch').html(rows);
}

maybe_name = function(data, key) { return data[key] ? data[key]['name'] : ''; }

message = function(str) { $('#message').html(str); }

kp = function(action) {
  $.getJSON(action, function(data) {
    list('song-lists', data['lists'], data['list']);
    list('songs', data['songs'], maybe_name(data, 'song'));
    list('triggers', data['triggers']);

    if (data['song']) {
      list('song', data['song']['patches'], maybe_name(data, 'patch'));
      if (data['patch']) {
        connection_rows(data['patch']['connections']);
      }
    }

    if (data['message'])
      message(data['message']);
  });
}

cycle_colors = function() {
  var base_class = color_schemes[color_scheme_index];
  if (color_scheme_index >= 0) {
    $('body').removeClass(base_class);
    $('.selected, th, td#appname').removeClass('reverse-' + base_class);
    $('tr, td, th').removeClass(base_class + '-border');
  }

  color_scheme_index = (color_scheme_index + 1) % color_schemes.length;

  base_class = color_schemes[color_scheme_index];
  $('body').addClass(base_class);
  $('.selected, th, td#appname').addClass('reverse-' + base_class);
  $('tr, td, th').addClass(base_class + '-border');

  color_scheme = base_class;
}

$.each({'j': 'next_patch',
        'down': 'next_patch',
        'k': 'prev_patch',
        'up': 'prev_patch',
        'n': 'next_song',
        'left': 'next_song',
        'p': 'prev_song',
        'right': 'prev_song',
        'esc': 'panic'},
       function(key, val) { $(document).bind('keydown', key, function() { kp(val); }); });
$(document).bind('keydown', 'c', function() { cycle_colors(); });

$(document).ready(function() {
  color_scheme_index = -1;
  cycle_colors();
  kp('status');
});
