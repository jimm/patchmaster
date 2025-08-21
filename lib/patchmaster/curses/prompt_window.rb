# frozen_string_literal: true

require 'curses'

module PM
  class PromptWindow
    MAX_WIDTH = 30

    include Curses

    def initialize(title, prompt)
      @title = title
      @prompt = prompt
      width = cols / 2
      width = MAX_WIDTH if width > MAX_WIDTH
      @win = Window.new(4, width, lines / 3, (cols - width) / 2)
    end

    def gets
      draw
      str = read_string
      cleanup
      str
    end

    def draw
      @win.box('|', '-')
      @win.setpos(0, 1)
      @win.attron(A_REVERSE) do
        @win.addstr(" #{@title} ")
      end

      @win.setpos(1, 1)
      @win.addstr(@prompt)

      @win.setpos(2, 1)
      @win.attron(A_REVERSE) do
        @win.addstr(' ' * (@win.maxx - 2))
      end

      @win.setpos(2, 1)
      @win.refresh
    end

    def read_string
      nocbreak
      echo
      curs_set(1)
      str = nil
      @win.attron(A_REVERSE) do
        str = @win.getstr
      end
      curs_set(0)
      noecho
      cbreak
      str
    end

    def cleanup
      @win.close
    end
  end
end
