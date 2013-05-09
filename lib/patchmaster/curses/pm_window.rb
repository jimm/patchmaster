require 'curses'
require 'delegate'

module PM
class PmWindow < SimpleDelegator

  include Curses

  attr_reader :win, :title_prefix
  attr_accessor :title

  # If title is nil then list's name will be used
  def initialize(rows, cols, row, col, title_prefix)
    @win = Window.new(rows, cols, row, col)
    super(@win)
    @title_prefix = title_prefix
    set_max_contents_len(cols)
  end

  def resize(rows, cols)
    @win.resize(rows, cols)
    set_max_contents_len(cols)
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

  def set_max_contents_len(cols)
    @max_contents_len = cols - 3 # 2 for borders
  end

  def make_fit(str)
    str = str[0..@max_contents_len] if str.length > @max_contents_len
    str
  end
end
end
