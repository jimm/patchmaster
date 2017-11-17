module PM

# Defines positions and sizes of windows. Rects contain [height, width, top,
# left], which is the order used by Curses::Window.new.
class Geometry

  include Curses

  def initialize
    @top_height = (lines() - 1) * 2 / 3
    @bot_height = (lines() - 1) - @top_height
    @top_width = cols() / 3

    @sls_height = @top_height / 3
    @sl_height = @top_height - @sls_height

    @info_width = cols() - (@top_width * 2)
    @info_left = @top_width * 2
  end

  def song_list_rect
    [@sl_height, @top_width, 0, 0]
  end

  def song_rect
    [@sl_height, @top_width, 0, @top_width]
  end

  def song_lists_rect
    [@sls_height, @top_width, @sl_height, 0]
  end

  def trigger_rect
    [@sls_height, @top_width, @sl_height, @top_width]
  end

  def patch_rect
    [@bot_height, cols(), @top_height, 0]
  end

  def message_rect
    [1, cols(), lines()-1, 0]
  end

  def info_rect
    [@top_height, @info_width, 0, @info_left]
  end

  def help_rect
    [lines() - 6, cols() - 6, 3, 3]
  end
end
end
