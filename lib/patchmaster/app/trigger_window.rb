require 'curses'

module PM
class TriggerWindow < PmWindow

  include Curses

  def initialize(rows, cols, row, col)
    super(rows, cols, row, col, nil)
    @title = 'Triggers '
  end

  def draw
    super
    pm = PM::PatchMaster.instance
    i = 0
    pm.inputs.each do |sym, instrument|
      instrument.triggers.each do |trigger|
        @win.setpos(i+1, 1)
        @win.addstr(make_fit(":#{sym} #{trigger.to_s}"))
        i += 1
      end
    end
  end
end
end

