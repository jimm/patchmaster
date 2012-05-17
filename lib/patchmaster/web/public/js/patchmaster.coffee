$ = jQuery
CONN_HEADERS = """
               <tr>
                 <th>Input</th>
                 <th>Chan</th>
                 <th>Output</th>
                 <th>Chan</th>
                 <th>Prog</th>
                 <th>Zone</th>
                 <th>Xpose</th>
                 <th>Filter</th>
               </tr>
               """

list_item = (val, highlighted_value) ->
  li_class = if val == highlighted_value then ' class="selected"' else ''
  "<li #{li_class}>#{val}</li>"

list = (id, vals, highlighted_value) ->
  lis = (list_item(val, highlighted_value) for val in vals)
  $('#' + id).html(lis.join("\n"))

connection_row = (conn) ->
  vals = (conn[key] for key in ['input', 'input_chan', 'output', 'output_chan', 'pc', 'zone', 'xpose', 'filter'])
  "<tr><td>#{vals.join('</td><td>')}</td></tr>"

connection_rows = (connections) ->
  rows = (connection_row(conn) for conn in connections)
  $('#patch').html(CONN_HEADERS + "\n" + rows.join("\n"))

maybe_name = (data, key) -> if data[key] then data[key]['name'] else ''

message = (str) -> $('#message').html(str)

kp = (action) ->
  $.getJSON(action, (data) ->
    list('song-lists', data['lists'], data['list'])
    list('songs', data['songs'], maybe_name(data, 'song'))
    list('triggers', data['triggers'])

    if data['song']?
      list('song', data['song']['patches'], maybe_name(data, 'patch'))
      if data['patch']?
        connection_rows(data['patch']['connections'])

    message(data['message']) if data['message']?
  )

bindings =
  'j': 'next_patch'
  'down': 'next_patch'
  'k': 'prev_patch'
  'up': 'prev_patch'
  'n': 'next_song'
  'left': 'next_song'
  'p': 'prev_song'
  'right': 'prev_song'
  'esc': 'panic'
f = (key, val) -> $(document).bind('keydown', key, () -> kp(val))
f(key, val) for key, val of bindings

kp('status')
