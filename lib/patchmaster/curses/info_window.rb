require 'curses'

module PM
class InfoWindow < PmWindow

  CONTENTS = File.join(File.dirname(__FILE__), 'info_window_contents.txt')

  include Curses

  attr_reader :text

  def initialize(rows, cols, row, col)
    super(rows, cols, row, col, nil)
    @info_text = IO.read(CONTENTS)
    text = nil
  end

  def text=(str)
    if str
      @text = str
      @title = 'Song Notes'
    else
      @text = @info_text
      @title = 'PatchMaster Help'
    end
  end

  def draw
    super
    i = 0
    @text.each_line do |line|
      @win.setpos(i+1, 1)
      @win.addstr(make_fit(line))
      i += 1
    end
  end

end
end
