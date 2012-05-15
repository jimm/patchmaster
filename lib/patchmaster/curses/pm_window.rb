require 'curses'

module PM
class PmWindow

  include Curses

  attr_reader :win, :title_prefix
  attr_accessor :title

  # If title is nil then list's name will be used
  def initialize(rows, cols, row, col, title_prefix)
    @win = Window.new(rows, cols, row, col)
    @title_prefix = title_prefix
    @max_contents_len = @win.maxx - 3 # 2 for borders
  end

  def refresh
    @win.refresh
  end

  def draw
    @win.clear
    @win.box(?|, ?-)
    return unless @title_prefix || @title

    @win.setpos(0, 1)
    @win.attron(A_REVERSE) {
      @win.addch(' ')
      @win.addstr("#{@title_prefix}: ") if @title_prefix
      @win.addstr(@title) if @title
      @win.addch(' ')
    }
  end

  def make_fit(str)
    str = str[0..@max_contents_len] if str.length > @max_contents_len
    str
  end
end
end
