require 'curses'

module PM
class InfoWindow

  CONTENTS = File.join(File.dirname(__FILE__), 'info_window_contents.txt')

  include Curses

  attr_reader :win

  TITLE = ' PatchMaster '

  def initialize(rows, cols, row, col)
    @win = Window.new(rows, cols, row, col)
  end

  def draw
    @win.setpos(0, (@win.maxx() - TITLE.length) / 2)
    @win.attron(A_REVERSE) {
      @win.addstr(TITLE)
    }
    @win.addstr("\n")
    IO.foreach(CONTENTS) { |line| @win.addstr(line) }
  end

  def refresh
    @win.refresh
  end

end
end
