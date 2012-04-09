require 'curses'
require 'singleton'
%w(list patch info prompt).each { |w| require "patchmaster/app/#{w}_window" }

module PM

class Main

  DEBUG_FILE = '/tmp/pm_debug.txt'

  include Singleton
  include Curses

  def initialize
    @pm = PatchMaster.instance
  end

  def no_midi!
    @pm.no_midi!
  end

  # File must be a Ruby file that returns an array of song lists.
  def load(file)
    @pm.load(file)
  end

  def run
    if $DEBUG
      @debug_file = File.open(DEBUG_FILE, 'a')
    end
    @pm.start
    begin
      config_curses
      create_windows
      message("Welcome to PatchMaster")

      loop do
        begin
          refresh_all
          ch = getch
          message("ch = #{ch}") if $DEBUG
          case ch
          when ?j, Patch::DOWN
            @pm.next_patch
          when ?k, Patch::UP
            @pm.prev_patch
          when ?n, Patch::LEFT
            @pm.next_song
          when ?p, Patch::RIGHT
            @pm.prev_song
          when ?g
            name = PromptWindow.new('Go To Song', 'Go to song:').gets
            @pm.goto_song(name)
          when ?t
            name = PromptWindow.new('Go To Song List', 'Go to Song List:').gets
            @pm.goto_song_list(name)
          when Patch::F1
            help
          when 27               # escape
            @pm.panic
            message('Panic sent')
          when ?l
            file = PromptWindow.new('Load', 'Load file:').gets
            begin
              @pm.load(file)
            rescue => ex
              message(ex.to_s)
            end
          when ?s
            file = PromptWindow.new('Save', 'Save into file:').gets
            begin
              @pm.save(file)
            rescue => ex
              message(ex.to_s)
            end
          when ?q
            break
          end
        rescue => ex
          message(ex.to_s)
          if $DEBUG
            @debug_file.puts caller.join("\n")
          end
        end
      end
    ensure
      close_screen
      @pm.stop
      if $DEBUG
        @debug_file.close
      end
    end
  end

  def config_curses
    init_screen
    cbreak                      # unbuffered input
    noecho                      # do not show typed patchs
    stdscr.patchpad(true)         # enable arrow patchs
    curs_set(0)                 # cursor: 0 = invisible, 1 = normal
  end

  def create_windows
    top_height = (lines() - 1) * 2 / 3
    bot_height = (lines() - 1) - top_height
    top_width = cols() / 3

    sls_height = top_height / 3
    sl_height = top_height - sls_height
    
    @song_lists_win = ListWindow.new(sls_height, top_width, 0, 0, nil)
    @song_lists_win.set_contents('Song Lists', @pm.song_lists)
    @song_list_win = ListWindow.new(sl_height, top_width, sls_height, 0, 'Song List')
    @song_win = ListWindow.new(top_height, top_width, 0, top_width, 'Song')
    @patch_win = PatchWindow.new(bot_height, cols(), top_height, 0, 'Patch')
    @message_win = Window.new(1, cols(), lines()-1, 0)

    @info_win = InfoWindow.new(top_height, cols() - (top_width * 2) - 1, 0, top_width * 2 + 1)
    @info_win.draw
  end

  def help
    message("Help: not yet implemented")
  end

  def message(str)
    if @message_win
      @message_win.clear
      @message_win.addstr(str)
      @message_win.refresh
    else
      $stderr.puts str
    end
    if $DEBUG
      @debug_file.puts "#{Time.now} #{str}"
      @debug_file.flush
    end
  end

  def refresh_all
    set_window_data
    [@song_lists_win, @song_list_win, @song_win, @patch_win].map(&:draw)
    [stdscr, @song_lists_win, @song_list_win, @song_win, @info_win, @patch_win, @message_win].map(&:refresh)
  end

  def set_window_data
    song_list = @pm.curr_song_list
    @song_list_win.set_contents(song_list.name, song_list.songs)
    song = song_list.curr_song
    if song
      @song_win.set_contents(song.name, song.patches)
      patch = song.curr_patch
      @patch_win.patch = patch
    else
      @song_win.set_contents(nil, nil)
      @patch_win.patch = nil
    end
  end

end
end
