require 'patchmaster/curses/pm_window'

module PM
class PatchWindow < PmWindow

  attr_reader :patch

  def patch=(patch)
    @title = patch ? patch.name : nil
    @patch = patch
    draw
  end

  def draw
    super
    @win.setpos(1, 1)
    draw_headers
    return unless @patch

    @patch.connections[0, visible_height].each_with_index do |connection, i|
      @win.setpos(i+2, 1)
      draw_connection(connection)
    end
  end

  def draw_headers
    @win.attron(A_REVERSE) {
      str = " Input          Chan | Output         Chan | Prog | Zone      | Xpose | Filter"
      str << ' ' * (@win.maxx - 2 - str.length)
      @win.addstr(str)
    }
  end

  def draw_connection(connection)
    str =  " #{'%16s' % connection.input.name}"
    str << " #{connection.input_chan ? ('%2d' % (connection.input_chan+1)) : '  '} |"
    str << " #{'%16s' % connection.output.name}"
    str << " #{'%2d' % (connection.output_chan+1)} |"
    str << if connection.pc?
             "  #{'%3d' % connection.pc_prog} |"
           else
             "      |"
           end
    str << if connection.zone
             " #{'%3s' % connection.note_num_to_name(connection.zone.begin)}" +
             " - #{'%3s' % connection.note_num_to_name(connection.zone.end)} |"
           else
             '           |'
           end
    str << if connection.xpose && connection.xpose != 0
             "   #{connection.xpose < 0 ? '' : ' '}#{'%2d' % connection.xpose.to_i} |"
           else
             "       |"
           end
    str << " #{filter_string(connection.filter)}"
    @win.addstr(make_fit(str))
  end

  def filter_string(filter)
    filter.to_s.gsub(/\s*#.*/, '').gsub(/\n\s*/, "; ")
  end

end
end
