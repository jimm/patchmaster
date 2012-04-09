require 'patchmaster/app/pm_window'

module PM
class ListWindow < PmWindow

  attr_reader :list

  def set_contents(title, list)
    @title, @list = title, list
    draw
  end

  def draw
    super
    return unless @list

    @list.each_with_index do |thing, i|
      @win.setpos(i+1, 1)
      @win.attron(A_REVERSE) if thing == @list.curr
      @win.addstr(make_fit(" #{thing.name} "))
      @win.attroff(A_REVERSE) if thing == @list.curr
    end
  end

end
end
