module PM

class Geometry

  include Curses
  
  attr_reader :top_height, :bot_height, :top_width, :sls_height, :sl_height,
    :third_height, :width, :left

  def initialize
    @top_height = (lines() - 1) * 2 / 3
    @bot_height = (lines() - 1) - @top_height
    @top_width = cols() / 3

    @sls_height = @top_height / 3
    @sl_height = @top_height - @sls_height

    @third_height = @top_height / 3
    @width = cols() - (@top_width * 2) - 1
    @left = @top_width * 2 + 1
  end

  def song_lists_rect
    [@sls_height, @top_width, 0, 0]
  end

  def song_list_rect
    [@sl_height, @top_width, @sls_height, 0]
  end

  def song_rect
    [@top_height, @top_width, 0, @top_width]
  end

  def patch_rect
    [@bot_height, cols(), @top_height, 0]
  end

  def message_rect
    [1, cols(), lines()-1, 0]
  end

  def trigger_rect
    [@third_height, @width, @third_height * 2, @left]
  end

  def info_rect
    [@third_height * 2, @width, 0, @left]
  end

  def move_and_resize(win, rect)
    win.move(rect[2], rect[3])
    win.resize(rect[0], rect[1])
  end
end
end

