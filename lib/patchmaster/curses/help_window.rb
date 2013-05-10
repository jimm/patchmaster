require 'curses'

module PM
class HelpWindow < PmWindow

  CONTENTS = File.join(File.dirname(__FILE__), 'info_window_contents.txt')

  include Curses

  attr_reader :text

  def initialize(rows, cols, row, col)
    super(rows, cols, row, col, nil)
    @text = IO.read(CONTENTS)
    @title = 'PatchMaster Help'
  end

  def draw
    super
    i = 0
    @text.each_line do |line|
      @win.setpos(i+2, 3)
      @win.addstr(make_fit(line.chomp))
      i += 1
    end
  end

end
end
