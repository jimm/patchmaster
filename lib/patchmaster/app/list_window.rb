require 'patchmaster/app/pm_window'

module PM
class ListWindow < PmWindow

  attr_reader :list

  # +curr_item_method_sym+ is a method symbol that is sent to
  # PM::PatchMaster to obtain the current item so we can highlight it.
  def set_contents(title, list, curr_item_method_sym)
    @title, @list, @curr_item_method_sym = title, list, curr_item_method_sym
    draw
  end

  def draw
    super
    return unless @list

    curr_item = PM::PatchMaster.instance.send(@curr_item_method_sym)
    @list.each_with_index do |thing, i|
      @win.setpos(i+1, 1)
      @win.attron(A_REVERSE) if thing == curr_item
      @win.addstr(make_fit(" #{thing.name} "))
      @win.attroff(A_REVERSE) if thing == curr_item
    end
  end

end
end
