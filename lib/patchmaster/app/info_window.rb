require 'curses'

module PM
class InfoWindow

  CONTENTS = File.join(File.dirname(__FILE__), 'info_window_contents.txt')

  include Curses

  attr_reader :win, :text

  TITLE = ' PatchMaster '

  def initialize(rows, cols, row, col)
    @win = Window.new(rows, cols, row, col)
    @text = IO.read(CONTENTS)
  end

  def draw
    @win.setpos(0, (@win.maxx() - TITLE.length) / 2)
    @win.attron(A_REVERSE) {
      @win.addstr(TITLE)
    }
    @win.addstr("\n")
    @text.each_line { |line| @win.addstr(line) }
  end

  def refresh
    @win.refresh
  end

end
end
