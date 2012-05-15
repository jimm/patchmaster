list = function(id, vals, highlighted_value) {
  var lis = '';
  $.each(vals, function(i, val) { 
    var li_class = val == highlighted_value ? ' class="selected"' : '';
    lis += "<li" + li_class + ">" + val + "</li>";
  });
  $('#' + id).html(lis);
}

connection_rows = function(connections) {
  var rows =
"<tr>\
  <th>Input</th>\
  <th>Chan</th>\
  <th>Output</th>\
  <th>Chan</th>\
  <th>Prog</th>\
  <th>Zone</th>\
  <th>Xpose</th>\
  <th>Filter</th>\
</tr>";

  $.each(connections, function(i, conn) {
    var row = "<tr>";
    row += ("<td>" + conn['input'] + "</td>");
    row += ("<td>" + conn['input_chan'] + "</td>");
    row += ("<td>" + conn['output'] + "</td>");
    row += ("<td>" + conn['output_chan'] + "</td>");
    row += ("<td>" + conn['pc'] + "</td>");
    row += ("<td>" + conn['zone'] + "</td>");
    row += ("<td>" + conn['xpose'] + "</td>");
    row += ("<td>" + conn['filter'] + "</td>");
    row += "</tr>";
    rows += row;
  });
  $('#patch').html(rows);
}

maybe_name = function(data, key) {
  return data[key] ? data[key]['name'] : '';
}

message = function(str) {
  $('#message').html(str);
}

kp = function(action) {
  message(action);
  $.getJSON(action, function(data) {
    console.log(data);          // DEBUG
    list('song-lists', data['lists'], data['list']);
    list('songs', data['songs'], maybe_name(data, 'song'));
    list('triggers', data['triggers']);

    if (data['song']) {
      list('song', data['song']['patches'], maybe_name(data, 'patch'));
      if (data['patch']) {
        connection_rows(data['patch']['connections']);
      }
    }

    // TODO rest of the data

    if (data['message'])
      message(data['message']);
  });
}

var d = $(document);
$.each({'j': 'next_patch',
        'down': 'next_patch',
        'k': 'prev_patch',
        'up': 'prev_patch',
        'n': 'next_song',
        'left': 'next_song',
        'p': 'prev_song',
        'right': 'prev_song',
        'esc': 'panic'},
       function(key, val) { d.bind('keydown', key, function() { kp(val); }); });

kp('status');
