require 'singleton'
require 'delegate'
require 'patchmaster/sorted_song_list'
require 'patchmaster/cursor'

module PM

# Global behavior: master list of songs, list of song lists, stuff like
# that.
#
# Typical use:
#
#   PatchMaster.instance.load("my_pm_dsl_file")
#   PatchMaster.instance.start
#   # ...when you're done
#   PatchMaster.instance.stop
class PatchMaster < SimpleDelegator

  DEBUG_FILE = '/tmp/pm_debug.txt'

  include Singleton

  attr_reader :inputs, :outputs, :all_songs, :song_lists, :no_midi

  # A Cursor to which we delegate incoming position methods (#song_list,
  # #song, #patch, #next_song, #prev_patch, etc.)
  attr_reader :cursor

  def initialize
    @cursor = Cursor.new(self)
    super(@cursor)

    if $DEBUG
      @debug_file = File.open(DEBUG_FILE, 'a')
    end
    @no_midi = false

    init_data
  end

  def no_midi!
    @no_midi = true
  end

  # Loads +file+. Does its best to restore the current song list, song, and
  # patch after loading.
  def load(file)
    restart = running?
    stop

    @cursor.mark
    init_data
    DSL.new(@no_midi).load(file)
    @loaded_file = file
    @cursor.restore

    if restart
      start(false)
    elsif @cursor.patch
      @cursor.patch.start
    end
  rescue => ex
    raise("error loading #{file}: #{ex}\n" + caller.join("\n"))
  end

  def save(file)
    DSL.new(@no_midi).save(file)
    message("saved #{file}")
  rescue => ex
    raise("error saving #{file}: #{ex}" + caller.join("\n"))
  end

  # Initializes the cursor and all data.
  def init_data
    @cursor.clear
    @inputs = {}
    @outputs = {}
    @song_lists = []
    @all_songs = SortedSongList.new('All Songs')
    @song_lists << @all_songs
  end

  # If +init_cursor+ is +true+ (the default), initializes current song list,
  # song, and patch. Starts a new thread that listens for MIDI input and
  # processes it.
  def start(init_cursor = true)
    @cursor.init if init_cursor
    @cursor.patch.start if @cursor.patch

    @input_threads = ThreadGroup.new
    @inputs.values.each do |input|
      t = Thread.new(input) do |instrument|
        loop { instrument.process_messages }
      end
      @input_threads.add(t)
      debug("#{Time.now} Thread #{t} started for #{input.name}")
    end
    @input_threads.enclose
  end

  # Stops the MIDI input threads.
  def stop
    if @input_threads
      @input_threads.list.each do |t|
        Thread.kill(t)
        debug("#{Time.now} Thread #{t} stopped")
      end
      @input_threads = nil
    end
    @cursor.patch.stop if @cursor.patch
  end

  def running?
    @input_threads
  end

  def panic
    @outputs.values.each do |out|
      MIDI_CHANNELS.times do |chan|
        out.midi_out([CONTROLLER + chan, CM_ALL_NOTES_OFF, 0])
      end
    end
  end

  def edit
    cmd = "#{ENV['VISUAL'] || ENV['EDITOR'] || 'vi'} #{@loaded_file}"
    message(cmd) if $DEBUG
    system(cmd)
    load(@loaded_file)
  end

  def debug(str)
    if $DEBUG
      f = @debug_file || $stderr
      f.puts str
      f.flush
    end
  end

  def close_debug_file
    @debug_file.close if @debug_file
  end
end
end
